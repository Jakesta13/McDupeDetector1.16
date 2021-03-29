#!/bin/bash
# Default avatar url uses an avatar from DiscordAvatars https://www.discordavatars.com/
discord="Discord Webhook URL Here"
avatar="https://www.discordavatars.com/wp-content/uploads/2020/05/meme-avatar-020.jpg"
name="Playerdata Save Error"

log="Log/file/location/latest.log"
mcrcon="/location/to/mcrcon"
counter=0
# Trip theshold for auto-ban
trip=3
# After how many detetions do you want to get a coordinates output (before a ban)?
# Note, once the Trip theshold is reached, coordinate and IP data is sent reguardless.
# For a 3 strike system, set the below to 2 and trip (above) to 3. First detection is an alert, second is login coords, third is a ban, coords + IP
firstCoords=2
# Trip theshold ban reason
ban="Dupe Suspicion"

# RCON Settings
IP="ServerIP"
port="12345"
pass="SecretPassword123"

# Function
function mcban {
if [ ! -z "${user}" ]; then
	${mcrcon} -H "${IP}" -P "${port}" -p "${pass}" "ban ${user} ${ban}"
fi
}
tail -q -F -n 1 "${log}" | grep --line-buffered -a "\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/WARN\]: Failed to save player data for"|
while read -r line; do
	if [ "${user}" == "${lastUser}" ]; then
		counter=$((counter + 1))
	else
		counter=0
		counter=$((counter +1))
	fi
	if [ "${counter}" -eq "${firstCoords}" ]; then
		coordsSecond=$(grep "${user}.*logged in with" "${log}" | tail -n 1 | sed -e "s/.*${user}.*logged in with entity id.*at (//" -e 's/)//' -e 's/,//g' -e 's/\.[0-9]*/ /g' -e 's/  / /g')
	fi
	user=$(echo "${line}" | awk '{print $10}')
	if [ "${counter}" -eq "${trip}" ]; then
		# Behold my Optomization power .. Unfortunately doesn't really work with the above coordsSecond though... but still BEHOLD!
		initGrab=$(grep "${user}.*logged in with" "${log}")
		coords=$(echo "${initGrab}" | sed -e "s/.*${user}.*logged in with entity id.*at (//" -e 's/)//' -e 's/,//g' -e 's/\.[0-9]*/ /g' -e 's/  / /g')
		userIP=$(echo "${initGrab}" | sed -e "s/.*${user}.*\[ logged.*//" -e "s=.*${user}\[/==" -e 's/:[0-9].*//')
		if [ -z "${coords}" ]; then
			coords="(Error, returned blank)"
			unset initGrab
		fi
		msg="Playerdata for ${user} was not able to save!\n${user} was auto-banned on suspicion based on detection #${trip}.\n\nCoords: ${coords}\nIP: ${userIP}"
		# Ban them and reset the counter
		mcban
		counter=0
		unset coords
		unset userIP
		unset initGrab
	else
		if [ ! -z "${coordsSecond}" ]; then
		msg="Playerdata for ${user} was not able to save!\nLikely duping, detection #${firstCoords}.\n\nCoords: ${coordsSecond}"
		else
		msg="Playerdata for ${user} was not able to save!\nThere's a chance this could be a dupe attempt."
		fi
	fi
	curl -s -H "Content-Type: application/json" -X POST --data '{"'"content"'": "'"${msg}"'" ,"'"username"'": "'"${name}"'" ,"'"avatar_url"'": "'"${avatar}"'"}' "${discord}"
	lastUser="${user}"
done
