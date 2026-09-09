#!/usr/bin/env node

import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const timeZone = process.env.TICKTICK_TIME_ZONE || "Europe/Copenhagen";

function localDateFor({ date }) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function shiftDate({ date, days }) {
  const shifted = new Date(`${date}T12:00:00Z`);
  shifted.setUTCDate(shifted.getUTCDate() + days);
  return shifted.toISOString().slice(0, 10);
}

async function ticktickJson({ args }) {
  const { stdout } = await execFileAsync("ticktick", [...args, "--json"], {
    maxBuffer: 10 * 1024 * 1024,
  });
  return JSON.parse(stdout);
}

function markdown({ value }) {
  return String(value).replaceAll("|", "\\|").replaceAll(/\r?\n/g, " ").trim();
}

function itemLabelFor({ task }) {
  if (task.isAllDay) return task.title;

  const time = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(new Date(task.dueDate || task.startDate));
  return `${task.title}, ${time}`;
}

async function main() {
  const today = localDateFor({ date: new Date() });
  const previousDay = shiftDate({ date: today, days: -1 });
  const nextDay = shiftDate({ date: today, days: 1 });

  const [projects, previousWindow, currentWindow] = await Promise.all([
    ticktickJson({ args: ["project", "list"] }),
    ticktickJson({
      args: ["task", "filter", "--start-date", previousDay, "--end-date", today, "--status", "0"],
    }),
    ticktickJson({
      args: ["task", "filter", "--start-date", today, "--end-date", nextDay, "--status", "0"],
    }),
  ]);

  const projectNames = new Map(projects.map(({ id, name }) => [id, name]));
  const tasks = [...new Map([...previousWindow, ...currentWindow].map((task) => [task.id, task])).values()]
    .filter((task) => {
      const date = task.dueDate || task.startDate;
      return date && localDateFor({ date: new Date(date) }) === today;
    })
    .map((task, index) => ({ task, index }))
    .sort((left, right) => {
      if (left.task.isAllDay !== right.task.isAllDay) return left.task.isAllDay ? 1 : -1;
      if (!left.task.isAllDay) {
        return new Date(left.task.dueDate || left.task.startDate) - new Date(right.task.dueDate || right.task.startDate);
      }
      return left.index - right.index;
    })
    .map(({ task }) => task);

  console.log("| Item | List | Tags |");
  console.log("|---|---|---|");

  if (tasks.length === 0) {
    console.log("| No open tasks | None | None |");
    return;
  }

  for (const task of tasks) {
    const tags = task.tags?.length ? task.tags.join(", ") : "None";
    console.log(
      `| ${markdown({ value: itemLabelFor({ task }) })} | ${markdown({ value: projectNames.get(task.projectId) || task.projectId })} | ${markdown({ value: tags })} |`,
    );
  }
}

main().catch((error) => {
  console.error(error.stderr?.trim() || error.message);
  process.exitCode = 1;
});
