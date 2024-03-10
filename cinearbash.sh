#!/usr/bin/env bash
clear
# ANSI escape code for green color
green="\e[32m"

# ANSI escape code for resetting color
reset="\e[0m"
#ASCII Art
echo -e "            █████
       ███████████████        █████████   ██████████         █████████   ██████████████████████
     ████████████████████     █████████   ████████████       █████████   ████████████████████
   ████████████████████████   █████████   █████████████      █████████   ██████████████████        ██████████
  █████████████████████████   █████████   ███████████████    █████████   █████████████████      ███████████████
 ██████████        █████      █████████   ████████████████   █████████   ██████████            ██████████████████
 ████████                     █████████   ██████████████████ █████████   ████████████████     ██████  ███    █████
█████████                     █████████   ████████████████████████████   ████████████████     █████    ██  █  ████
█████████                     █████████   ████████████████████████████   ████████████████     █████     █    █████
 ████████                     █████████   ██████████ █████████████████   ████████████████     ████  ██  █  █  ████
 ██████████        █████      █████████   ██████████  ████████████████   ██████████            ██████████████████
  █████████████████████████   █████████   ██████████    ██████████████   █████████████████      ████████████████
   ████████████████████████   █████████   ██████████     █████████████   ██████████████████       ████████████
    █████████████████████     █████████   ██████████       ███████████   ███████████████████
       ████████████████       █████████   ██████████        ██████████   ██████████████████████
           ████████
"
# Login
source cinear.cfg

login_url="https://id.cine.ar/v1.5/auth/login"
API_URI="https://play.cine.ar/api/v1.7"
production_info_url="${API_URI}/INCAA/prod/"
player_url="https://player.cine.ar/odeon/"

# Para logearse y obtener el token
login() {
    response=$(curl -s -X POST "$login_url" -H "Content-Type: application/json" -d '{"email": "'$email'", "password": "'$password'"}')
    token=$(echo "$response" | jq -r '.token')
    if [ "$token" = "null" ]; then
        echo "Login failed or token not found in the response"
        exit 1
    else
        echo -e "${green}Logeado correctamente!${reset}"
    fi
}

# Obtener el perfil de usuario
get_user_pid() {
    local token=$(< token.txt)
    local user_url="${API_URI}/user"
    perfil=$(curl -s -X GET "$user_url" -H "Authorization: Bearer $token" | jq -r '.perfiles[0].id')
    echo "Perfil ID: $perfil"
}

# Obtener informacion a partir del SID
get_production_info() {
    formatted_sid=$(printf "%04d" $sid)
    local sid="$1"
    local token=$(< token.txt)
    response=$(curl -s -X GET "${production_info_url}/${sid}?perfil=${perfil}" -H "Authorization: Bearer $token" -H "Content-Type: application/json")
    # Attempt to parse the response as JSON to handle escaped strings
    parsedResponse=$(echo "$response" | jq -r 'fromjson?')
    # Check if the response contains the specific error message
    errorMsg=$(echo "$parsedResponse" | jq -r '.message // empty')
    # Ver si es pelicula o serie
    tipo_text=$(echo "$response" | jq -r '.tipos[0].text')
    titulo=$(echo "$response" | jq -r '.tit')
    anio=$(echo "$response" | jq -r '.an')

    safe_folder_name=$(echo "$tipo_text")
    echo "$tipo_text"

    if [ "$errorMsg" = "producción no encontrada o incompatible con las características del perfil" ]; then
        echo -e "\e[0;31mSID Vacio${reset}"
    else
    # Bajar Pelis
        if [ "$tipo_text" = "Películas" ] || [ "$tipo_text" = "Cortos" ]; then
            # Crea la carpeta si no existe
            mkdir -p "./$safe_folder_name"
            # Crear JSON y TXT con resumen
            echo "$response" > "./$safe_folder_name/${formatted_sid}.json"
            echo "$response" | jq '{Titulo: .tit, Anio: .an, Duracion: .dura, Sinopsis: .sino, Genero: .gens}' > "./$safe_folder_name/${formatted_sid}.txt"

            # Conseguir el poster
            echo -e "${green}Descargando Cartel${reset}"
            poster=$(echo "$response" | jq -r '.afis[0]')
            poster_url="https://img.cine.ar/image/${poster}/context/odeon_afiche_prod"
            curl -o "./$safe_folder_name/${formatted_sid}.jpg" "$poster_url"
            echo "Poster downloaded as ./$safe_folder_name/${formatted_sid}.jpg"

            #OBTENER VIDEO

            source="INCAA"
            url=$(echo "${player_url}?s=${source}&i=${sid}&p=${perfil}&t=${token}")
            # Generating the digest
            clave="${source}${sid}${perfil}${token}ARSAT"
            digest=$(echo -n "$clave" | md5sum | cut -d ' ' -f1) # MD5 hash
            digest_clave=$(echo -n "$digest" | xxd -r -p | base64) # Base64 encoding
            video=$(curl -s -H "Authorization: Bearer ${token}" -H "X-Auth-Key: ${digest_clave}" "${url}" | jq -r '.url')

            echo -e "${green}Descargando Video${reset}"
            #mpv "$video"
            #Generar archivo de video"
            hlsdl -b "$video" -o "./$safe_folder_name/${formatted_sid} - ${titulo} (${anio}).ts"
        else
            if  [ "$tipo_text" = "Series" ]; then
                echo $safe_folder_name
                #Crea la carpeta
                mkdir -p "./$safe_folder_name/$formatted_sid"
                echo "$response" > "./$safe_folder_name/$formatted_sid/${formatted_sid}.json"
                echo "$response" | jq '{Titulo: .tit, Anio: .an, Duracion: .dura, Sinopsis: .sino, Genero: .gens}' > "./$safe_folder_name/$formatted_sid/${formatted_sid}.txt"

                # Assuming 'items' is a JSON array containing episodes details
                # and 'json_response' contains the JSON response from the API
                items=$(echo "$response" | jq '.items')

                # Get the length of the items array
                length=$(echo "$items" | jq 'length')

                # Loop through each item and extract details
                for (( i=0; i<length; i++ ))
                do
                    # Extract details for each episode
                    episode_title=$(echo "$items" | jq -r ".[$i].tit")
                    season_number=$(echo "$items" | jq -r ".[$i].tempo")
                    episode_number=$(echo "$items" | jq -r ".[$i].capi")
                    episode_sid=$(echo "$items" | jq -r ".[$i].sid")
                    formatted_season=$(printf "%02d" $season_number)
                    formatted_episode=$(printf "%02d" $episode_number)

                    # Display the extracted details
                    echo -e "${green}Descargando Episodio${reset}"
                    echo "Season $season_number Episode $episode_number - $episode_title (SID: $episode_sid)"

                    #obtener JSON y TXT
                    episodio=$(curl -s -X GET "${production_info_url}/${episode_sid}?perfil=${perfil}" -H "Authorization: Bearer $token" -H "Content-Type: application/json")
                    echo "$episodio" > "./$safe_folder_name/${formatted_sid}/${formatted_sid} - ${titulo}  S${formatted_season}E${formatted_episode}(SID:${episode_sid}).json"

                #OBTENER VIDEO
                            source="INCAA"
                            url=$(echo "${player_url}?s=${source}&i=${episode_sid}&p=${perfil}&t=${token}")
                            # Generating the digest
                            clave="${source}${episode_sid}${perfil}${token}ARSAT"
                            digest=$(echo -n "$clave" | md5sum | cut -d ' ' -f1) # MD5 hash
                            digest_clave=$(echo -n "$digest" | xxd -r -p | base64) # Base64 encoding
                            video=$(curl -s -H "Authorization: Bearer ${token}" -H "X-Auth-Key: ${digest_clave}" "${url}" | jq -r '.url')
                            #mpv "$video"
                            #Generar archivo de video"
                            hlsdl -b "$video" -o "./$safe_folder_name/${formatted_sid}/${formatted_sid} - ${titulo}  S${formatted_season}E${formatted_episode}(SID:${episode_sid}).ts"
                done
            fi
        fi
    fi
}

# Arranca la fiesta
login
get_user_pid

read -p "SID inicial: " start_number
read -p "SID final: " end_number
read -p "Ingresar el maximo de peliculas para descargar al mismo tiempo: " concurrent_limit

current_jobs=0

for ((sid = start_number; sid <= end_number; sid++)); do
echo -e "Comenzando la descarga de SID:${sid}"
get_production_info "$sid"  &  # Send the job to the background

    ((current_jobs++))
    if ((current_jobs >= concurrent_limit)); then
        wait -n  # Wait for at least one job to finish before continuing
        ((current_jobs--))
    fi
done
wait  # Wait for all background jobs to finish
echo "terminado"
