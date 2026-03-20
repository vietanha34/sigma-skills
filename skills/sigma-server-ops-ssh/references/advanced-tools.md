# Advanced Tools

Use this file when the normal workflow is not enough:

- `master`, `dump`, and `progress` are inconclusive
- the log only says `internal error` or another generic failure
- you need the exact ffmpeg command, input structure, first PTS, or keyframe cadence

## Environment

Remote tools live under:

- `/usr/local/sigma/sigma-video-dir/tools`

Before running any of these tools, export:

```bash
export LD_LIBRARY_PATH=/usr/local/sigma/sigma-video-dir/lib:$LD_LIBRARY_PATH
cd /usr/local/sigma/sigma-video-dir/tools
```

Do not assume the library path is already set in non-interactive SSH shells.

## Tool Selection

- Use `cmd` when you need the real ffmpeg command line for one running job.
- Use `probe` when you need ffprobe-level structure for one input.
- Use `pts` when you need the first PTS quickly.
- Use `kf` when you suspect ABR/input sync problems and need keyframe cadence.
- Use `logd` or `log` when the built-in rotation helpers are more convenient than reading raw files.

## cmd

Usage:

```bash
./cmd <jobprefix>
```

Example:

```bash
./cmd 2e359fe1
```

What it does:

- finds the running sigma worker by job prefix
- prints the actual ffmpeg command line
- exposes the concrete input URLs, target URLs, mux/hls/tee options, and timeouts

Use it when:

- the API/logs do not clearly show which target failed
- you need to know the exact ffmpeg flags in effect
- the error is generic like `internal error`, `open error`, `io error`, or `input/output error`

Practical rules:

- derive `<jobprefix>` from the runtime job key, usually the first 8 characters of `_id` or map key
- use `cmd` before guessing whether the failing side is input or output
- include the exact failing URL/path from `cmd` in the incident summary

## probe

Usage:

```bash
./probe <input>
```

Example:

```bash
./probe 'udp://239.0.0.63:5000?localaddr=127.0.0.1'
```

What it does:

- prints ffprobe JSON for the input
- shows codec, pid, resolution, frame rate, sample rate, start time, and stream count

Use it when:

- input format looks suspicious
- logs mention `NO_AUDIO_DATA`, `NO_VIDEO_DATA`, `INVALID_INPUT_DATA`, `PPS_ID_NOT_FOUND`
- you need to confirm whether all expected streams are really present

Check next:

- missing audio/video/data streams
- unexpected codec/profile/format
- unstable or weird `start_time`

## pts

Usage:

```bash
./pts <input>
```

Example:

```bash
./pts 'udp://239.0.0.63:5000?localaddr=127.0.0.1'
```

What it does:

- prints the first detected `start_time`

Use it when:

- you need a fast PTS comparison across multiple ABR inputs
- `ASYNC_STREAM`, `CANT_SYNC_INPUT`, or similar sync faults are suspected

Practical rules:

- compare all inputs in the same ABR set
- large deltas between sibling inputs are a useful sync clue, but not a diagnosis by themselves

## kf

Usage:

```bash
./kf <input>
```

Example:

```bash
./kf 'udp://239.0.0.63:5000?localaddr=127.0.0.1'
```

What it does:

- streams keyframe timestamps continuously

Use it when:

- ABR inputs may be misaligned
- GOP cadence may be unstable
- `ASYNC_STREAM` or `GOP_INVALID` is suspected

Safety rules:

- never run `kf` unbounded
- stop after about 10 keyframes or a short timeout
- prefer `timeout` plus `head`

Example bounded use:

```bash
timeout 20s ./kf 'udp://239.0.0.63:5000?localaddr=127.0.0.1' | head -n 10
```

Interpretation:

- regular intervals suggest stable GOP cadence
- irregular intervals or long gaps support sync/source instability hypotheses

## logd and log

Usage:

- `./logd` to view current `.debug`
- `./logd .sys` to view current `.sys`
- `./log <days-back> -n <lines> <suffix>`

Examples:

```bash
./logd
./logd .sys
./log 1 -n 200 .debug
./log 2 -n 100 .cmd
```

Use them when:

- you want rotated log access without building file paths manually
- you need a quick previous-day log sample

## Suggested Escalation Flow

1. Start with `master`, `dump`, `progress`, and bounded logs.
2. If one job is still ambiguous, run `cmd <jobprefix>`.
3. If the input itself is suspicious, run `probe <input>`.
4. If sync is suspicious, compare `pts` across sibling inputs.
5. If GOP cadence is suspicious, run bounded `kf`.
6. Add only the strongest findings to the report; do not paste full ffmpeg commands unless needed.
