inventory <- read.csv("inventory.csv", stringsAsFactors = FALSE)

#' List all cars in the inventory
#' @get /car/
listCars <- function(){
  inventory
}

#' Lookup a car by ID
#' @param id:int The ID of the car to get
#' @get /car/<id:int>
getCar <- function(id){
  inventory[inventory$id == id,]
}

validateCar <- function(car){
  if (nchar(car$make) == 0){
    return("No make specified")
  }
  if (nchar(car$model) == 0){
    return("No make specified")
  }
  if (as.integer(car$year) == 0){
    return("No year specified")
  }
  NULL
}

#' Add a car to the inventory
#' @post /car/
addCar <- function(make, model, edition, year, miles, price){
  newId <- max(inventory$id) + 1
  car <- list(
    id = newId,
    make = make,
    model = model,
    edition = edition,
    year = year,
    miles = miles,
    price = price
  )
  valid <- validateCar(car)
  if (!is.null(valid)){
    stop("Invalid car: ", valid)
  }
  inventory <<- rbind(inventory, car)
  getCar(newId)
}

#' Update a car in the inventory
#' @param id:int The ID of the car to update
#' @put /car/<id:int>
updateCar <- function(id, make, model, edition, year, miles, price){
  updated <- list(
    id = id,
    make = make,
    model = model,
    edition = edition,
    year = year,
    miles = miles,
    price = price
  )

  if (!(id %in% inventory$id)){
    stop("No such ID: ", id)
  }

  valid <- validateCar(updated)
  if (!is.null(valid)){
    stop("Invalid car: ", valid)
  }
  inventory[inventory$id == id, ] <<- updated
  getCar(id)
}

#' Delete a car from the inventory
#' @param id:int The ID of the car to delete
#' @delete /car/<id:int>
deleteCar <- function(id){
  if (!(id %in% inventory$id)){
    stop("No such ID: ", id)
  }
  inventory <<- inventory[inventory$id != id,]
}
