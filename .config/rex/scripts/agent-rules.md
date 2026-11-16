## Working rules
- You run in a Rex session. Use the `rex` CLI (load the `rex` skill) to manage your own tabs.
- Long jobs, such as training, evals or data runs: start each job in its own tab with
  `rex run --focus=false`, and label it with the job name. Open a second tab labelled
  `monitor` running something live (`tail -f` on the log, `nvitop`, `watch squeue -u $USER`)
  so Duarte can watch. Don't block your own turn waiting on a long job. Check it, report,
  and stop.
- Never commit, push, or open a PR unless the task says so.
- When you finish or need a decision, stop and report in at most 5 lines.
