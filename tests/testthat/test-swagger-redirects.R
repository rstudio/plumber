context("Swagger redirects")

test_that("swagger_redirects returns correct redirect structure with default apiPath", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = NULL
    ),
    {
      redirects <- swagger_redirects()

      # Check that we have the expected redirect paths
      expect_true("/__swagger__/" %in% names(redirects))
      expect_true("/__swagger__/index.html" %in% names(redirects))

      # Verify redirect structure uses relative paths
      expect_equal(redirects[["/__swagger__/"]]$route, "../__docs__/")
      expect_equal(
        redirects[["/__swagger__/index.html"]]$route,
        "../__docs__/index.html"
      )

      # Verify handler is a function
      expect_true(is.function(redirects[["/__swagger__/"]]$handler))
      expect_true(is.function(redirects[["/__swagger__/index.html"]]$handler))
    }
  )
})

test_that("swagger_redirects respects custom apiPath", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/api/v1"
    ),
    {
      redirects <- swagger_redirects()

      # Redirect keys should include the apiPath prefix
      expect_true("/api/v1/__swagger__/" %in% names(redirects))
      expect_true("/api/v1/__swagger__/index.html" %in% names(redirects))

      # Targets use relative paths
      expect_equal(redirects[["/api/v1/__swagger__/"]]$route, "../__docs__/")
      expect_equal(
        redirects[["/api/v1/__swagger__/index.html"]]$route,
        "../__docs__/index.html"
      )
    }
  )
})

test_that("swagger_redirects returns empty list when disabled", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(plumber.legacyRedirects = FALSE),
    {
      redirects <- swagger_redirects()
      expect_length(redirects, 0)
      expect_equal(redirects, list())
    }
  )
})

test_that("swagger redirect handler returns 301 response", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = NULL
    ),
    {
      redirects <- swagger_redirects()
      handler <- redirects[["/__swagger__/"]]$handler

      # Create mock request and response
      req <- make_req("GET", "/__swagger__/")
      res <- PlumberResponse$new()

      # Execute handler
      result <- handler(req, res)

      # Verify redirect response uses relative path
      expect_equal(res$status, 301)
      expect_equal(res$headers$Location, "../__docs__/")
      expect_equal(res$body, "redirecting...")
    }
  )
})

test_that("swagger redirect handler works with apiPath", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/api/v2"
    ),
    {
      redirects <- swagger_redirects()
      handler <- redirects[["/api/v2/__swagger__/index.html"]]$handler

      # Create mock request and response
      req <- make_req("GET", "/api/v2/__swagger__/index.html")
      res <- PlumberResponse$new()

      # Execute handler
      result <- handler(req, res)

      # Verify redirect response uses relative path
      expect_equal(res$status, 301)
      expect_equal(res$headers$Location, "../__docs__/index.html")
      expect_equal(res$body, "redirecting...")
    }
  )
})

test_that("swagger redirects are mounted on plumber router", {
  skip_if_not_installed("withr")
  skip_if_not_installed("swagger")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = ""
    ),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      # Mount docs (which includes redirects)
      mount_docs(
        pr = pr,
        host = "127.0.0.1",
        port = 8000,
        docs_info = docs_info,
        callback = NULL,
        quiet = TRUE
      )

      # Check that redirect endpoints are registered
      endpoints <- pr$endpoints[["__no-preempt__"]]
      endpoint_paths <- sapply(endpoints, function(e) e$path)

      expect_true("/__swagger__/" %in% endpoint_paths)
      expect_true("/__swagger__/index.html" %in% endpoint_paths)
    }
  )
})

test_that("swagger redirects work on mounted router with apiPath", {
  skip_if_not_installed("withr")
  skip_if_not_installed("swagger")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/myapp"
    ),
    {
      pr <- pr()
      pr$handle("GET", "/endpoint", function() "data")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      mount_docs(
        pr = pr,
        host = "127.0.0.1",
        port = 8000,
        docs_info = docs_info,
        callback = NULL,
        quiet = TRUE
      )

      # Find the redirect endpoint (should be prefixed with apiPath)
      endpoints <- pr$endpoints[["__no-preempt__"]]
      swagger_endpoint <- NULL
      for (ep in endpoints) {
        if (ep$path == "/myapp/__swagger__/") {
          swagger_endpoint <- ep
          break
        }
      }

      expect_false(is.null(swagger_endpoint))

      # Test the redirect by routing a request
      req <- make_req("GET", "/myapp/__swagger__/", pr = pr)
      res <- PlumberResponse$new()

      result <- pr$route(req, res)

      # Verify redirect uses relative path
      expect_equal(res$status, 301)
      expect_equal(res$headers$Location, "../__docs__/")
    }
  )
})

test_that("swagger redirects can be unmounted", {
  skip_if_not_installed("withr")
  skip_if_not_installed("swagger")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = ""
    ),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      # Mount docs
      mount_docs(
        pr = pr,
        host = "127.0.0.1",
        port = 8000,
        docs_info = docs_info,
        callback = NULL,
        quiet = TRUE
      )

      # Verify redirects are mounted
      endpoints_before <- pr$endpoints[["__no-preempt__"]]
      paths_before <- sapply(endpoints_before, function(e) e$path)
      expect_true("/__swagger__/" %in% paths_before)

      # Unmount docs
      unmount_docs(pr, docs_info)

      # Verify redirects are unmounted
      endpoints_after <- pr$endpoints[["__no-preempt__"]]
      if (length(endpoints_after) > 0) {
        paths_after <- sapply(endpoints_after, function(e) e$path)
        expect_false("/__swagger__/" %in% paths_after)
        expect_false("/__swagger__/index.html" %in% paths_after)
      } else {
        # No endpoints left is also valid
        expect_length(endpoints_after, 0)
      }
    }
  )
})

test_that("swagger redirect overwrite warning appears when route exists", {
  skip_if_not_installed("withr")
  skip_if_not_installed("swagger")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = ""
    ),
    {
      pr <- pr()
      # Pre-register a route at the same path as the redirect
      pr$handle("GET", "/__swagger__/", function() "existing")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      # Mounting docs should show overwrite warning
      expect_message(
        mount_docs(
          pr = pr,
          host = "127.0.0.1",
          port = 8000,
          docs_info = docs_info,
          callback = NULL,
          quiet = TRUE
        ),
        "Overwriting existing GET endpoint: /__swagger__/"
      )
    }
  )
})

test_that("swagger redirects work with nested apiPath", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/api/v1/myapp"
    ),
    {
      redirects <- swagger_redirects()

      # Verify redirect keys include full nested path
      expect_true("/api/v1/myapp/__swagger__/" %in% names(redirects))
      expect_true("/api/v1/myapp/__swagger__/index.html" %in% names(redirects))

      # Targets use relative paths
      expect_equal(
        redirects[["/api/v1/myapp/__swagger__/"]]$route,
        "../__docs__/"
      )
      expect_equal(
        redirects[["/api/v1/myapp/__swagger__/index.html"]]$route,
        "../__docs__/index.html"
      )
    }
  )
})

test_that("swagger redirects respect environment variable for apiPath", {
  skip_if_not_installed("withr")

  withr::with_envvar(
    list(PLUMBER_APIPATH = "/env/api"),
    {
      withr::with_options(
        list(
          plumber.legacyRedirects = TRUE,
          plumber.apiPath = NULL  # Clear option to use env var
        ),
        {
          redirects <- swagger_redirects()

          # Should use environment variable in redirect keys
          expect_true("/env/api/__swagger__/" %in% names(redirects))
          # Targets use relative paths
          expect_equal(
            redirects[["/env/api/__swagger__/"]]$route,
            "../__docs__/"
          )
        }
      )
    }
  )
})

test_that("swagger redirects handle empty apiPath correctly", {
  skip_if_not_installed("withr")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = ""
    ),
    {
      redirects <- swagger_redirects()

      # Empty string should behave same as NULL, uses relative paths
      expect_equal(redirects[["/__swagger__/"]]$route, "../__docs__/")
      expect_equal(
        redirects[["/__swagger__/index.html"]]$route,
        "../__docs__/index.html"
      )
    }
  )
})

test_that("multiple swagger redirects on same router work independently", {
  skip_if_not_installed("withr")
  skip_if_not_installed("swagger")

  withr::with_options(
    list(
      plumber.legacyRedirects = TRUE,
      plumber.apiPath = "/v1"
    ),
    {
      pr <- pr()
      pr$handle("GET", "/test", function() "test")

      docs_info <- list(
        enabled = TRUE,
        docs = "swagger",
        args = list()
      )

      mount_docs(pr, "127.0.0.1", 8000, docs_info, NULL, TRUE)

      # Test both redirect endpoints (with apiPath prefix)
      req1 <- make_req("GET", "/v1/__swagger__/", pr = pr)
      res1 <- PlumberResponse$new()
      pr$route(req1, res1)

      req2 <- make_req("GET", "/v1/__swagger__/index.html", pr = pr)
      res2 <- PlumberResponse$new()
      pr$route(req2, res2)

      # Both should redirect correctly using relative paths
      expect_equal(res1$status, 301)
      expect_equal(res1$headers$Location, "../__docs__/")

      expect_equal(res2$status, 301)
      expect_equal(res2$headers$Location, "../__docs__/index.html")
    }
  )
})
