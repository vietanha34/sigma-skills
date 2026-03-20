# Error Codes

Use this file when sigma logs contain normalized worker error codes such as `(code: INPUT_TIMEOUT)`.

## Log Format

Typical worker log line:

- `[05-26 02:32:55] Input timeout (code: INPUT_TIMEOUT)`

Interpretation:

- `[05-26 02:32:55]`: event timestamp in UTC
- `Input timeout`: human-readable error message
- `(code: INPUT_TIMEOUT)`: normalized error code for triage

Use the code as the primary classifier. Use the message, target URL, and surrounding lines to decide which dependency actually failed.

## Reading Rules

- Distinguish between:
  - input-side faults
  - output-side faults
  - processing/resource faults
  - config/create-job faults
- If the same code repeats for one job/session ID, treat it as one persistent incident.
- If the code is marked `create-only` below, expect retries to keep failing until the job is restarted or the config is fixed.
- For output-related codes, always identify the concrete failing target URL or destination path before concluding root cause.
- Some codes can belong to more than one side. Use the URL/path in the same line to decide whether it is input or output.

## High-Signal Groups

### Input-side dominant

- `TIMEOUT`
- `INPUT_TIMEOUT`
- `GOP_INVALID`
- `ASYNC_STREAM`
- `STREAM_NOT_FOUND` `create-only`
- `NO_AUDIO_DATA` `create-only`
- `NO_VIDEO_DATA` `create-only`
- `INVALID_INPUT_DATA`
- `CANT_SYNC_INPUT`
- `STREAM_MISSING`
- `INPUT_PACKET_TOO_SMALL`
- `AAC_PACKET_TOO_SHORT`
- `PPS_ID_NOT_FOUND`

Typical causes:

- source mất sóng hoặc jitter nặng
- nguồn trả dữ liệu sai format
- ABR input không đồng bộ
- thiếu elementary stream cần thiết khi khởi tạo

Check next:

- `progress.input[].state`, `progress.input[].msg`, `showing`
- bitrate input có còn lên không
- log quanh thời điểm đầu tiên bị lỗi
- nguồn UDP/SRT/RTMP tương ứng có còn tồn tại hay không

### Output-side dominant

- `OUTPUT_TIMEOUT`
- `UNABLE_TO_OPEN_RESOURCE`
- `INITIALIZING_OUTPUT_STREAM` `create-only`
- `END_OF_FILE`
- `FAILED_TO_RESOLVE_HOSTNAME`

Typical causes:

- đích ghi file/chunk quá chậm hoặc bị treo
- manifest/origin path không sẵn sàng
- DNS hoặc hostname của output bị lỗi
- output HLS/file target có vấn đề về storage/path

Check next:

- target URL/path trong `progress.target[]`
- `now.origin` và `now.nginx` cho HLS/origin symptoms
- disk/path/permission nếu output là filesystem

### Input or output transport

- `INPUT_OUTPUT_ERROR`
- `IO_ERROR`
- `CONNECTION_REFUSED`
- `CONNECTION_TIMEOUT`
- `CANNOT_OPEN_CONNECTION`
- `URL_READ_ERROR`
- `NO_ROUTE_TO_HOST` `create-only`
- `CONNECTION_RESET_BY_PEER`
- `BROKEN_PIPE`
- `OPEN_ERROR`
- `CLOSE_ERROR`
- `NETWORK_IS_UNREACHABLE`

Typical causes:

- TCP/SRT/RTMP endpoint không reachable
- listener phía đích không chạy
- network route/DNS/firewall lỗi
- peer reset connection sau khi job đã chạy

Check next:

- target hoặc source URL cụ thể trong log line
- endpoint đó có đang nghe cổng không
- lỗi có xảy ra ngay sau `Process started` không
- chỉ một target lỗi hay toàn bộ target cùng lỗi

Interpretation hints:

- `CONNECTION_REFUSED`: thường là service đích không lắng nghe hoặc manifest/origin service unavailable
- `BROKEN_PIPE` / `CONNECTION_RESET_BY_PEER`: thường là peer đóng kết nối sau khi stream đã thiết lập
- `NO_ROUTE_TO_HOST` / `NETWORK_IS_UNREACHABLE`: nghiêng về network path, VLAN, route, firewall

### Processing/resource dominant

- `PACKET_QUEUE_IS_FULL`
- `PACKET_QUEUE_OVERFLOW`
- `MEMORY_IS_FULL`
- `TRANSCODE_TIMEOUT`
- `ENCODE_TIMEOUT`
- `SYNC_SEQUENCE`
- `MUXER_PCR_ERROR`
- `MUXER_ERROR`
- `GPU_ENCODE_SESSION_OVERFLOW`

Typical causes:

- thiếu tài nguyên CPU/GPU/RAM
- queue nội bộ không xử lý kịp
- encoder/muxer bị nghẽn
- job count vượt giới hạn session của encoder GPU

Check next:

- `dump.system.cpu`, `ramUsed`, `system.gpu[]`
- `dump.queue`, `task.started`, `system.monitor[]`
- `process.cpu`, `process.ram` của job trong `progress`
- có nhiều job cùng lỗi cùng lúc hay không

Interpretation hints:

- `PACKET_QUEUE_*`: có thể do input, output, hoặc processing; chỉ kết luận machine pressure khi có thêm bằng chứng từ `dump`
- `MEMORY_IS_FULL`: ưu tiên kiểm tra RAM/swap và process footprint
- `GPU_ENCODE_SESSION_OVERFLOW`: nghiêng mạnh về giới hạn GPU session hoặc scheduling/capacity

### Config or create-job dominant

- `OPTION_NOTFOUND` `create-only`
- `PROTOCOL_NOTFOUND` `create-only`
- `INVALID_ARGUMENT` `create-only`
- `FEATURE_NOT_ENABLED`
- `CANT_START_OVERLAY`
- `DUPLICATE_STREAM_ID`

Typical causes:

- payload tạo job sai
- protocol/filter/feature không được build hoặc không bật
- tham số output/profile không hợp lệ
- overlay/filter config lỗi

Check next:

- config/job payload
- `/etc/sigma-machine/config/*.yaml`
- app capability/feature flags
- restart job sau khi sửa config, không chỉ chờ auto-retry

## Consolidated Code Guide

| Code | Main side | Notes |
| --- | --- | --- |
| `TIMEOUT` | Input | Generic timeout, often source loss |
| `PACKET_QUEUE_IS_FULL` | Input/Output/Processing | Queue cannot drain fast enough |
| `PACKET_QUEUE_OVERFLOW` | Input/Output/Processing | Same triage family as queue full |
| `MEMORY_IS_FULL` | Processing | RAM pressure |
| `INPUT_TIMEOUT` | Input | Source timeout |
| `OUTPUT_TIMEOUT` | Output | Target timeout |
| `TRANSCODE_TIMEOUT` | Processing | Transcode pipeline stalled |
| `ENCODE_TIMEOUT` | Processing | Encoder-side stall |
| `GOP_INVALID` | Input | Bad GOP cache/input structure |
| `ASYNC_STREAM` | Input | ABR inputs out of sync |
| `ASYNC_PROFILE` | Output | ABR outputs out of sync |
| `INPUT_OUTPUT_ERROR` | Input/Output | Use URL/path to decide side |
| `IO_ERROR` | Input/Output | Generic read/write fault |
| `CONNECTION_REFUSED` | Input/Output | Service reachable by host but not accepting |
| `CONNECTION_TIMEOUT` | Input/Output | Handshake or network timeout |
| `CANNOT_OPEN_CONNECTION` | Input/Output | Session cannot be created |
| `URL_READ_ERROR` | Input/Output | URL fetch/read failure |
| `OPTION_NOTFOUND` | Config | `create-only` |
| `PROTOCOL_NOTFOUND` | Config | `create-only` |
| `STREAM_NOT_FOUND` | Input | `create-only` |
| `UNABLE_TO_OPEN_RESOURCE` | Output | Target resource/path cannot be opened |
| `NO_ROUTE_TO_HOST` | Input/Output | `create-only` network path issue |
| `INVALID_ARGUMENT` | Config | `create-only` |
| `INITIALIZING_OUTPUT_STREAM` | Output | `create-only` output init failure |
| `CONNECTION_RESET_BY_PEER` | Input/Output | Peer aborted session |
| `BROKEN_PIPE` | Input/Output | Pipe/socket broken after start |
| `NO_AUDIO_DATA` | Input | `create-only` |
| `NO_VIDEO_DATA` | Input | `create-only` |
| `FEATURE_NOT_ENABLED` | Config | Feature unsupported or disabled |
| `CANT_START_OVERLAY` | Config | Overlay/filter init failed |
| `NO_SUCH_FILE_OR_DIRECTORY` | Input/Output | Missing file/path |
| `END_OF_FILE` | Output | Common on output side teardown |
| `FAILED_TO_RESOLVE_HOSTNAME` | Output | DNS failure |
| `INVALID_INPUT_DATA` | Input | Source payload malformed |
| `CANT_SYNC_INPUT` | Input | Input cannot sync |
| `STREAM_MISSING` | Input | Stream disappeared or missing |
| `OPEN_ERROR` | Input/Output | Generic open failure |
| `CLOSE_ERROR` | Input/Output | Generic close failure |
| `SYNC_SEQUENCE` | Processing | Internal sync/sequence issue |
| `INPUT_PACKET_TOO_SMALL` | Input | Packet malformed |
| `AAC_PACKET_TOO_SHORT` | Input | AAC packet malformed |
| `PPS_ID_NOT_FOUND` | Input | H.264/H.265 parameter set issue |
| `GPU_ENCODE_SESSION_OVERFLOW` | Processing | GPU session exhaustion |
| `MUXER_PCR_ERROR` | Processing | Muxer/PCR issue |
| `MUXER_ERROR` | Processing | Muxer buffer overflow |
| `ERR_INPUT_ERROR` / `INPUT_ERROR` | Input | Generic input failure |
| `NETWORK_IS_UNREACHABLE` | Input/Output | Network path down |

## Java-Service and API Validation Messages

The Java constants file also includes service-level validation and API-side messages. These are not worker runtime codes, but they matter when triaging create/update failures.

Common config/create examples:

- `MSG_TOKEN_INVALID`
- `MSG_NAME_EXISTED`
- `MSG_CANT_READ_INPUT`
- `MSG_GPU_INVALID`
- `MSG_GPU_ENCODER_UNSUPPORT`
- `MSG_GPU_DECODER_UNSUPPORT`
- `MSG_PORT_USED`
- `MSG_NO_PROFILE_FOUND`
- `MSG_NO_TARGET_FOUND`
- `MSG_STREAM_NOT_FOUND`
- `MSG_NO_AUDIO_FOUND`
- `MSG_NO_VIDEO_FOUND`
- `MSG_CODEC_NOT_SUPPORTED`
- `MSG_TARGET_TYPE_NOT_SUPPORTED`
- `MSG_PROTOCOL_NOT_SUPPORT`
- `MSG_INPUT_NOT_READY`
- `MSG_NO_INPUT_AVAILABLE`
- `MSG_TARGET_MISSING_PROFILE`
- `MSG_APP_ERROR`
- `MSG_CONFIG_ERROR`
- `MSG_VERSION_NOT_SUPPORT`

Interpretation:

- If the job never starts and the error appears during API/config handling, prefer these service-level messages over worker codes.
- Errors in this family usually require config correction or job recreation, not passive waiting for auto-retry.

## Practical Triage Rules

1. If the code is input-dominant and `progress.input[].state` is bad, blame the source path first.
2. If the code is output-dominant and only one target URL fails, blame the target side first.
3. If the code is queue/memory/encode related and multiple channels degrade together, check machine capacity before blaming a single channel.
4. If the code is `create-only`, expect auto-retry to be insufficient; plan a config fix and job restart.
5. If no normalized code appears, fall back to message text patterns in `log-signals.md`.
