#!/bin/bash
## Counts lines that match disconnects and if a death-by-firework occurs AFTER they disconnect then it's an auto-ban.
### Should work, it was tested via simulating the same console lines (Legit disconnect, then injected a spoofed death message).

## Log settings
log="/path/to/server/latest.log"

## Discord Settings
# Default avatar url is from DiscordAvatars - https://www.discordavatars.com/
discord="DISCORD WEBHOOK URL"
avatar="https://www.discordavatars.com/wp-content/uploads/2020/05/meme-avatar-071.jpg"
name="Firework Dupe"

## mcrcon settings
# mcrcon file location
mcrcon="/path/to/mcrcon"

# Connection
IP="example.com"
port="12345"
pass="SecretPassword123"

# Ban Message
ban="Dupe Suspicion"

## Break this script with a word/phrase
### Must match exact wording and is case-sensitive.
# Note: Don't use single quotes .. it breaks.. the break word... Haven't tried it via setting a vairable though...
TheBreakWord="Why isnt Cobble Here?"

### Functions, don't touch
function mcban {
	if [ -n "${bangDeadPlayer}" ]; then
		"${mcrcon}" -H "${IP}" -P "${port}" -p "${pass}" "ban ${bangDeadPlayer} ${ban}"
	fi
}
function sendMessage {
	if [ -n "${bangDeadPlayer}" ]; then
		curl -s -H "Content-Type: application/json" -X POST --data '{"'"content"'": "'"${msg}"'" ,"'"username"'": "'"${name}"'" ,"'"avatar_url"'": "'"${avatar}"'"}' "${discord}"
	fi
}
counter=0
# Tail command, Grep will listen to Disconnects, and firework deaths.
tail -q -F -n 1 "${log}" | grep --line-buffered -a "\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/INFO\]:"|
while read -r line; do
	# Pi Addition - Killword
	breakWord=$(echo "${line}" | grep "\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/INFO\]: <.*> ${TheBreakWord}")
	if [ -n "${breakWord}" ]; then
		break
	fi
	# Clean up line. As a limitation, we do the filtering here.
	line=$(echo "${line}" | grep "\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/INFO\]: .* lost connection: Disconnected\|\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/INFO\]: .* left the game\|\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[Server thread/INFO\]: .* went off with a bang")
	if [ -n "${line}" ]; then
		# Grab the lines we need to test for... each one should set off a counter.
		# In testing, the quit messages AND the death message occur at the same time (Within the same second!)
		lConnection=$(echo "${line}" | grep "lost connection" | awk '{print $4}')
		leftGame=$(echo "${line}" | grep "left the game" | awk '{print $4}')
		bangDead=$(echo "${line}" | grep "went off with a bang" | awk '{print $4}')
		# Check if any of these are in the output, also should check if the username matches btw.
		# When we get bangDead, check if the last message was from the user (leftGame).
		if [ -n "${lConnection}" ] || [ -n "${leftGame}" ] || [ -n "${bangDead}" ]; then
			counter=$((counter +1))
			# Store users
			if [ -n "${lConnection}" ]; then
				lConnectionPlayer="${lConnection}"
			fi
			if [ -n "${leftGame}" ]; then
				leftGamePlayer="${leftGame}"
			fi
			if [ -n "${bangDead}" ]; then
				bangDeadPlayer="${bangDead}"
			fi
			# Hold up, we do not want to count when someone dies normally, that is immoral!
			if [ -z "${lConnectionPlayer}" ] && [ -z "${leftGamePlayer}" ] && [ -n "${bangDeadPlayer}" ]; then
				# Oh and ONLY if bangDeadPlayer does not match
				userMinusCheck=$(echo "${leftGamePlayer} ${lConnectionPlayer}" | grep -o "${bangDeadPlayer}" | wc -l)
				# If user matches 1 or less, then minus 1 from the counter, if matches 2, then im sorry man.
				if [ "${userMinusCheck}" -lt "1" ]; then
					counter=$((counter -1))
					unset bangDeadPlayer
				fi
			fi
			# If counter has reached 3, then notify and ban the player under dupe suspicion.
				if [ "${counter}" -eq "3" ]; then
					# ban player
					userCheck=$(echo "${leftGamePlayer} ${lConnectionPlayer}" | grep -o "${bangDeadPlayer}" | wc -l)
					# If 2 matches, then we are in buissness.
					if [ "${userCheck}" -eq 2 ]; then
						# With the power of minor optomization I shall now save some extra greps.
						initGrab=$(grep "${bangDeadPlayer}.*logged in with" "${log}" | tail -n 1)
						coords=$(echo "${initGrab}" | sed -e "s/.*${user}.*logged in with entity id.*at (//" -e 's/)//' -e 's/,//g' -e 's/\.[0-9]*/ /g' -e 's/  / /g')
						playerIP=$(echo "${initGrab}" | sed -e "s/.*${user}.*\[ logged.*//" -e "s=.*${user}\[/==" -e 's/:[0-9].*//')
						mcban
						# Send discord Message
						msg="${bangDeadPlayer} was banned for possibly firework duping.\n\nLast login coords: ${coords}\nIP: ${playerIP}"
						sendMessage
						counter=0
					fi
				fi
		else
			counter=$((counter -1))
		fi
	else
		if [ "${counter}" -ne "0" ]; then
			counter=$((counter -1))
		fi
	fi
done
