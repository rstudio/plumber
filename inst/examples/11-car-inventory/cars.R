inventory <- read.csv("inventory.csv", stringsAsFactors = FALSE)

#* @apiTitle Auto Inventory Manager
#* @apiDescription Manage the inventory of an automobile
#*   store using an API.

#* List all cars in the inventory
#* @get /car/
listCars <- function(){
  inventory
}

#* Lookup a car by ID
#* @param id The ID of the car to get
#* @get /car/<id:int>
#* @response 404 No car with the given ID was found in the inventory.
getCar <- function(id, res){
  car <- inventory[inventory$id == id,]
  if (nrow(car) == 0){
    res$status <- 404
  }
  car
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

#* Add a car to the inventory
#* @post /car/
#* @param make:character The make of the car
#* @param model:character The model of the car
#* @param edition:character Edition of the car
#* @param year:int Year the car was made
#* @param miles:int The number of miles the car has
#* @param price:numeric The price of the car in USD
#* @response 400 Invalid user input provided
addCar <- function(make, model, edition, year, miles, price, res){
  newId <- max(inventory$id) + 1

  #FIXME: If any of these args are missing then we fatally err when we reference
  # them here.
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
    res$status <- 400
    return("Invalid car: ", valid)
  }
  inventory <<- rbind(inventory, car)
  getCar(newId)
}

#* Update a car in the inventory
#* @param id:int The ID of the car to update
#* @param make:character The make of the car
#* @param model:character The model of the car
#* @param edition:character Edition of the car
#* @param year:int Year the car was made
#* @param miles:int The number of miles the car has
#* @param price:numeric The price of the car in USD
#* @put /car/<id:int>
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

#* Delete a car from the inventory
#* @param id:int The ID of the car to delete
#* @delete /car/<id:int>
deleteCar <- function(id){
  if (!(id %in% inventory$id)){
    stop("No such ID: ", id)
  }
  inventory <<- inventory[inventory$id != id,]
}
