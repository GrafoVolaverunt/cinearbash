# cinearbash
![cine.ar ASCII logo](https://raw.githubusercontent.com/GrafoVolaverunt/cinearbash/main/cinearlogo.png)

Bash script que descarga pelis, cortos y series desde cine.ar junto con el cartel de las mismas y un archivo json con su metadata

## Dependencias
El script necesita curl, hlsdl y jq para funcionar

## ¿Como usar el script?
Primero tenés que abrir el archivo cinear.cfg donde e ingresar tu usuario y contraseña de cine.ar.

Una vez hecho esto, el script está listo para ser ejecutado.

El número SID que pide es el numero que identifica cada produccion en el sitio, lo podes encontrar en la URL cada vez que entras a ver una pelicula.

Por ejemplo:
```
https://play.cine.ar/INCAA/produccion/8026
```

## IMPORTANTE:
Cuando el script te pregunte acerca de cuantas pelis bajar al mismo tiempo recomiendo no poner numeros demasiado grandes. Por lo que probe hasta ahora de a 5 funciona bien
