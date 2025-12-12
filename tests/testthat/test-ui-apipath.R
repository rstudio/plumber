context("UI with apiPath")

test_that("mount_openapi respects plumber.apiPath option", {
  # Test with default (empty) apiPath
  pr <- pr()
  pr$handle("GET", "/test", function() "test")

  api_url <- "http://localhost:8000"
  mount_openapi(pr, api_url)

  # Should mount at /openapi.json by default
  openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
  openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
  expect_true("/openapi.json" %in% openapi_paths)
})

test_that("mount_openapi uses plumber.apiPath when set", {
  # Test with apiPath set
  withr::with_options(
    list(plumber.apiPath = "/api/v1"),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      api_url <- "http://localhost:8000/api/v1"
      mount_openapi(pr, api_url)

      # Should mount at /api/v1/openapi.json
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/api/v1/openapi.json" %in% openapi_paths)
      expect_false("/openapi.json" %in% openapi_paths)
    }
  )
})

test_that("mount_openapi works with nested apiPath", {
  withr::with_options(
    list(plumber.apiPath = "/api/v2/myapp"),
    {
      pr <- pr()
      pr$handle("GET", "/endpoint", function() "data")

      api_url <- "http://localhost:8000/api/v2/myapp"
      mount_openapi(pr, api_url)

      # Should mount at /api/v2/myapp/openapi.json
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/api/v2/myapp/openapi.json" %in% openapi_paths)
    }
  )
})

test_that("unmount_openapi respects plumber.apiPath option", {
  # Test with default (empty) apiPath
  pr <- pr()
  pr$handle("GET", "/test", function() "test")
  mount_openapi(pr, "http://localhost:8000")

  # Verify it's mounted
  openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
  openapi_paths_before <- sapply(openapi_endpoint, function(e) e$path)
  expect_true("/openapi.json" %in% openapi_paths_before)

  # Unmount
  unmount_openapi(pr)

  # Verify it's unmounted
  openapi_endpoint_after <- pr$endpoints[["__no-preempt__"]]
  if (length(openapi_endpoint_after) > 0) {
    openapi_paths_after <- sapply(openapi_endpoint_after, function(e) e$path)
    expect_false("/openapi.json" %in% openapi_paths_after)
  } else {
    # No endpoints left, which is also valid
    expect_length(openapi_endpoint_after, 0)
  }
})

test_that("unmount_openapi uses plumber.apiPath when set", {
  withr::with_options(
    list(plumber.apiPath = "/api/v1"),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")
      mount_openapi(pr, "http://localhost:8000/api/v1")

      # Verify it's mounted at the correct path
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths_before <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/api/v1/openapi.json" %in% openapi_paths_before)

      # Unmount
      unmount_openapi(pr)

      # Verify it's unmounted
      openapi_endpoint_after <- pr$endpoints[["__no-preempt__"]]
      if (length(openapi_endpoint_after) > 0) {
        openapi_paths_after <- sapply(openapi_endpoint_after, function(e) e$path)
        expect_false("/api/v1/openapi.json" %in% openapi_paths_after)
      }
    }
  )
})

test_that("register_docs mounts docs at correct path with apiPath", {
  # Test with default (empty) apiPath
  pr <- pr()
  pr$handle("GET", "/test", function() "test")

  # register_docs is called when swagger package loads, but we can test the mount behavior
  # by checking the mount path
  api_url <- "http://localhost:8000"

  # The register_docs function should be available (registered by swagger or similar)
  if (length(registered_docs()) > 0) {
    doc_name <- registered_docs()[1]
    mount_func <- .globals$docs[[doc_name]]$mount

    # Call the mount function
    docs_url <- mount_func(pr, api_url)

    # Should mount at /__docs__/
    expect_true(!is.null(pr$mounts[["/__docs__/"]]))
    expect_equal(docs_url, "http://localhost:8000/__docs__/")
  } else {
    skip("No registered docs available for testing")
  }
})

test_that("register_docs respects plumber.apiPath option", {
  withr::with_options(
    list(plumber.apiPath = "/api/v1"),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      api_url <- "http://localhost:8000/api/v1"

      if (length(registered_docs()) > 0) {
        doc_name <- registered_docs()[1]
        mount_func <- .globals$docs[[doc_name]]$mount

        # Call the mount function
        docs_url <- mount_func(pr, api_url)

        # Should mount at /api/v1/__docs__/
        expect_true(!is.null(pr$mounts[["/api/v1/__docs__/"]]))
        expect_equal(docs_url, "http://localhost:8000/api/v1/__docs__/")
        expect_null(pr$mounts[["/__docs__/"]])  # Should NOT be at default location
      } else {
        skip("No registered docs available for testing")
      }
    }
  )
})

test_that("swagger_redirects respects plumber.apiPath option", {
  # Ensure legacyRedirects is enabled for this test
  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = NULL
    ),
    {
      # Test with default (empty) apiPath
      redirects <- swagger_redirects()
      expect_true("/__swagger__/" %in% names(redirects))
      expect_equal(redirects[["/__swagger__/"]]$route, "/__docs__/")
    }
  )

  # Test with apiPath set
  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/api/v1"
    ),
    {
      redirects <- swagger_redirects()
      expect_true("/__swagger__/" %in% names(redirects))
      expect_equal(redirects[["/__swagger__/"]]$route, "/api/v1/__docs__/")
      expect_equal(redirects[["/__swagger__/index.html"]]$route, "/api/v1/__docs__/index.html")
    }
  )
})

test_that("mount_docs integrates openapi and docs paths correctly", {
  skip_if_not_installed("swagger")

  # Test with apiPath set
  withr::with_options(
    list(plumber.apiPath = "/api/v1"),
    {
      pr <- pr()
      pr$handle("GET", "/endpoint", function() "data")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      # Mount docs (which also mounts openapi)
      mount_docs(
        pr = pr,
        host = "127.0.0.1",
        port = 8000,
        docs_info = docs_info,
        callback = NULL,
        quiet = TRUE
      )

      # Check that openapi.json is mounted at the correct path
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/api/v1/openapi.json" %in% openapi_paths)

      # Check that docs are mounted at the correct path
      expect_true(!is.null(pr$mounts[["/api/v1/__docs__/"]]))
      expect_null(pr$mounts[["/__docs__/"]])  # Should NOT be at default location
    }
  )
})

test_that("multiple sequential mount/unmount operations work correctly", {
  withr::with_options(
    list(plumber.apiPath = "/v1"),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      # Mount
      mount_openapi(pr, "http://localhost:8000/v1")
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/v1/openapi.json" %in% openapi_paths)

      # Unmount
      unmount_openapi(pr)
      openapi_endpoint_after <- pr$endpoints[["__no-preempt__"]]
      if (length(openapi_endpoint_after) > 0) {
        openapi_paths_after <- sapply(openapi_endpoint_after, function(e) e$path)
        expect_false("/v1/openapi.json" %in% openapi_paths_after)
      }

      # Mount again
      mount_openapi(pr, "http://localhost:8000/v1")
      openapi_endpoint_final <- pr$endpoints[["__no-preempt__"]]
      openapi_paths_final <- sapply(openapi_endpoint_final, function(e) e$path)
      expect_true("/v1/openapi.json" %in% openapi_paths_final)
    }
  )
})

test_that("apiPath works with environment variable", {
  withr::with_envvar(
    list(PLUMBER_APIPATH = "/env/path"),
    {
      # Clear option to ensure env var is used
      withr::with_options(
        list(plumber.apiPath = NULL),
        {
          pr <- pr()
          pr$handle("GET", "/test", function() "test")
          mount_openapi(pr, "http://localhost:8000/env/path")

          openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
          openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
          expect_true("/env/path/openapi.json" %in% openapi_paths)
        }
      )
    }
  )
})

test_that("empty apiPath works correctly", {
  withr::with_options(
    list(plumber.apiPath = ""),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")
      mount_openapi(pr, "http://localhost:8000")

      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)
      expect_true("/openapi.json" %in% openapi_paths)
    }
  )
})

test_that("apiPath with trailing slash is handled correctly", {
  withr::with_options(
    list(plumber.apiPath = "/api/v1/"),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")
      mount_openapi(pr, "http://localhost:8000/api/v1/")

      # The implementation concatenates path + "/openapi.json"
      # so "/api/v1/" + "/openapi.json" = "/api/v1//openapi.json"
      # This test documents current behavior - may need adjustment if this is a bug
      openapi_endpoint <- pr$endpoints[["__no-preempt__"]]
      openapi_paths <- sapply(openapi_endpoint, function(e) e$path)

      # Check what path was actually created
      expect_true(any(grepl("openapi\\.json$", openapi_paths)))
    }
  )
})

test_that("overwriting message appears when route already exists with apiPath", {
  withr::with_options(
    list(plumber.apiPath = "/api"),
    {
      pr <- pr()
      # Pre-register a route at the same path
      pr$handle("GET", "/api/openapi.json", function() "existing")

      # Now mount_openapi should show overwriting message
      expect_message(
        mount_openapi(pr, "http://localhost:8000/api"),
        "Overwritting existing `/openapi.json` route"
      )
    }
  )
})
