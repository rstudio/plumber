
#' Provision a DigitalOcean plumber server
#'
#' Create (if required), install the necessary prerequisites, and
#' deploy a sample plumber application on a DigitalOcean virtual machine.
#' @param dropletId The numeric identifier of the DigitalOcean server that you want to provision (see [analogsea::droplets()]). If empty, a new DigitalOcean server will be created.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
do_provision <- function(dropletId, ...){
  droplet <- NULL
  if (missing(dropletId)){
    # No dropletId provided; create a new server
    message("THIS ACTION COSTS YOU MONEY! Provisioning a new server ",
              "for which you will get a bill from DigitalOcean.")

    createArgs <- list(...)
    createArgs$tags <- c(createArgs$tags, "plumber")
    createArgs$image <- "ubuntu-16-04-x64"

    droplet <- do.call(analogsea::droplet_create, createArgs)
  } else if (!is.numeric(dropletId)){
    stop("dropletId must be numeric; cannot use: '", dropletId, "' of type ", typeof(dropletId))
  } else {
    # otherwise we were given a numeric droplet ID; use that.
    droplet <- analogsea::droplet(id=dropletId)
  }

  # Wait for the droplet to come online
  analogsea::droplet_wait(droplet)

  # I often still get a closed port after droplet_wait returns. Buffer for just a bit
  Sys.sleep(15)

  # Provision
  droplet %>%
    debian_add_swap() %>%
    install_new_r() %>%
    install_r_package("plumber")
}

install_new_r <- function(droplet){
  droplet %>%
    droplet_ssh(c("echo 'deb https://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list",
                  "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9")) %>%
    debian_apt_get_update() %>%
    debian_install_r()
}


