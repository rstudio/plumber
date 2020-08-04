inventory <- read.csv("inventory.csv", stringsAsFactors = FALSE)

#* @apiTitle Auto Inventory Manager
#* @apiDescription Manage the inventory of an automobile
#*   store using an API.
#* @apiTag cars Functionality having to do with the management of
#*   car inventory.

#* List all cars in the inventory
#* @get /car/
#* @tag cars
listCars <- function(){
  inventory
}

#* Lookup a car by ID
#* @param id The ID of the car to get
#* @get /car/<id:int>
#* @response 404 No car with the given ID was found in the inventory.
#* @tag cars
getCar <- function(id, res){
  car <- inventory[inventory$id == id,]
  if (nrow(car) == 0){
    res$status <- 404
  }
  car
}

validateCar <- function(make, model, year){
  if (missing(make) || nchar(make) == 0){
    return("No make specified")
  }
  if (missing(model) || nchar(model) == 0){
    return("No make specified")
  }
  if (missing(year) || as.integer(year) == 0){
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
#* @tag cars
addCar <- function(make, model, edition, year, miles, price, res){
  newId <- max(inventory$id) + 1

  valid <- validateCar(make, model, year)
  if (!is.null(valid)){
    res$status <- 400
    return(list(errors=paste0("Invalid car: ", valid)))
  }

  car <- list(
    id = newId,
    make = make,
    model = model,
    edition = edition,
    year = year,
    miles = miles,
    price = price
  )

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
#* @tag cars
updateCar <- function(id, make, model, edition, year, miles, price, res){

  valid <- validateCar(make, model, year)
  if (!is.null(valid)){
    res$status <- 400
    return(list(errors=paste0("Invalid car: ", valid)))
  }

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

  inventory[inventory$id == id, ] <<- updated
  getCar(id)
}

#* Delete a car from the inventory
#* @param id:int The ID of the car to delete
#* @delete /car/<id:int>
#* @tag cars
deleteCar <- function(id, res){
  if (!(id %in% inventory$id)){
    res$status <- 400
    return(list(errors=paste0("No such ID: ", id)))
  }
  inventory <<- inventory[inventory$id != id,]
}
