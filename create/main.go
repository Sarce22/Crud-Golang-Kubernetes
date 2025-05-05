package main

import (
	"log"
	"net/http"

	"crud-microservice/config"
	"crud-microservice/controllers"
	"crud-microservice/repositories"
	"crud-microservice/services"

	"github.com/gorilla/mux"
)

func main() {
	config.ConnectDB()

	collection := config.DB.Collection("users")
	repo := repositories.NewUserRepository(collection)
	service := services.NewUserService(repo)
	controller := controllers.NewUserController(service)

	router := mux.NewRouter()
	router.HandleFunc("/create", controller.CreateUser).Methods("POST")

	http.HandleFunc("/hola", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("¡Hola Mundo! 🌎"))
	})

	log.Println("🚀 Servidor corriendo en http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", router))
}
