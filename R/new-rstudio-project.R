# This function is invoked when creating a new Plumber API project in the
# RStudio IDE. The function will be called when the user invokes the
# New Project wizard using the project template defined in the file at:
#
#   inst/rstudio/templates/project/new-rstudio-project.dcf

# The new project template mechanism is documented at:
# https://rstudio.github.io/rstudio-extensions/rstudio_project_templates.html

newRStudioProject <- function(path, ...) {

  # ensure path exists
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  # generate plumber.R
  sample <- c(
    "#",
    "# This is a Plumber API. In RStudio 1.2 or newer you can run the API by",
    "# clicking the 'Run API' button above.",
    "#",
    "# In RStudio 1.1 or older, see the Plumber documentation for details",
    "# on running the API.",
    "#",
    "# Find out more about building APIs with Plumber here:",
    "#",
    "#    https://www.rplumber.io/",
    "#",
    "",
    "library(plumber)",
    "",
    "#* @apiTitle Plumber Example API",
    "",
    "#* Echo back the input",
    "#* @param msg The message to echo",
    "#* @get /echo",
    "function(msg=\"\"){",
    "  list(msg = paste0(\"The message is: '\", msg, \"'\"))",
    "}",
    "",
    "#* Plot a histogram",
    "#* @png",
    "#* @get /plot",
    "function(){",
    "  rand <- rnorm(100)",
    "  hist(rand)",
    "}",
    "",
    "#* Return the sum of two numbers",
    "#* @param a The first number to add",
    "#* @param b The second number to add",
    "#* @post /sum",
    "function(a, b){",
    "  as.numeric(a) + as.numeric(b)",
    "}",
    ""
  )

  contents <- paste(sample, collapse = "\n")

  # write to index file
  writeLines(contents, con = file.path(path, "plumber.R"))
}
