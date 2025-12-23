## Comments

#### 2025-12-22

Dear maintainer,

Please see the problems shown on
<https://cran.r-project.org/web/checks/check_results_plumber.html>.

Please correct before 2026-01-12 to safely retain your package on CRAN.

Best wishes,
The CRAN Team


#### 2025-12-22

Output from CRAN package checks:

```
CRAN Package Check Results for Package plumber
Last updated on 2025-12-22 15:51:00 CET.

Flavor	Version	Tinstall	Tcheck	Ttotal	Status	Flags
r-devel-linux-x86_64-debian-clang	1.3.1	12.50	86.23	98.73	OK
r-devel-linux-x86_64-debian-gcc	1.3.1	8.08	62.75	70.83	ERROR
r-devel-linux-x86_64-fedora-clang	1.3.1	22.00	131.83	153.83	OK
r-devel-linux-x86_64-fedora-gcc	1.3.1	24.00	182.79	206.79	OK
r-devel-windows-x86_64	1.3.1	14.00	107.00	121.00	OK
r-patched-linux-x86_64	1.3.1	13.59	77.77	91.36	OK
r-release-linux-x86_64	1.3.0	13.25	78.78	92.03	OK
r-release-macos-arm64	1.3.1	3.00	48.00	51.00	OK
r-release-macos-x86_64	1.3.1	8.00	146.00	154.00	OK
r-release-windows-x86_64	1.3.1	16.00	104.00	120.00	OK
r-oldrel-macos-arm64	1.3.1	3.00	52.00	55.00	OK
r-oldrel-macos-x86_64	1.3.1	9.00	186.00	195.00	OK
r-oldrel-windows-x86_64	1.3.1	19.00	124.00	143.00	OK
Check Details
Version: 1.3.1
Check: tests
Result: ERROR
    Running ‘spelling.R’ [0s/0s]
    Running ‘testthat.R’ [21s/34s]
  Running the tests in ‘tests/testthat.R’ failed.
  Complete output:
    > library(testthat)
    > library(plumber)
    >
    > test_check("plumber")
    [ FAIL 1 | WARN 0 | SKIP 15 | PASS 1952 ]

    ══ Skipped tests (15) ══════════════════════════════════════════════════════════
    • On CRAN (15): 'test-cookies.R:41:3', 'test-deprecated.R:60:3',
      'test-find-port.R:40:3', 'test-find-port.R:56:3', 'test-legacy.R:20:3',
      'test-options.R:22:3', 'test-plumber-print.R:2:3',
      'test-plumber-print.R:60:3', 'test-plumber.R:67:3',
      'test-serializer-device.R:21:1', 'test-serializer-htmlwidgets.R:20:3',
      'test-static.R:23:3', 'test-zzz-openapi.R:302:3',
      'test-zzz-plumb_api.R:10:3', 'test-zzz-plumb_api.R:65:3'

    ══ Failed tests ════════════════════════════════════════════════════════════════
    ── Failure ('test-zzzz-include.R:34:5'): Includes work ─────────────────────────
    Expected `val$body` to match regexp "<html.*<img (role=\"img\" )?src=\"data:image/png;base64.*</html>\\s*$".
    Actual text:
    ✖ │ <!DOCTYPE html>
      │
      │ <html>
      │
      │ <head>
      │
      │ <meta charset="utf-8" />
      │ <meta name="generator" content="pandoc" />
      │ <meta http-equiv="X-UA-Compatible" content="IE=EDGE" />
      │
      │
      │ <meta name="author" content="Jeff Allen" />
      │
      │ <meta name="date" content="2015-06-14" />
      │
      │ <title>test</title>
      │
      | [...truncated...]


    [ FAIL 1 | WARN 0 | SKIP 15 | PASS 1952 ]
    Error:
    ! Test failures.
    Execution halted
Flavor: r-devel-linux-x86_64-debian-gcc
```

#### 2024-12-12

I've made the test more robust to different html output formats. No `./R` code has been changed.

Best,
Barret
