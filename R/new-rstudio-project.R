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

  # copy 'resources' folder to path
  resources = system.file("rstudio", "templates", "project", "resources",
                           package = "plumber", mustWork = TRUE)

  files = list.files(resources, recursive = TRUE, include.dirs = FALSE)
  source = file.path(resources, files)
  target = file.path(path, files)
  file.copy(source, target)
}
