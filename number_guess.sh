#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r username
username_escaped=$(printf '%s' "$username" | sed "s/'/''/g")

user_stats=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username = '$username_escaped';")
if [[ -z $user_stats ]]; then
	echo "Welcome, $username! It looks like this is your first time here."
else
	IFS='|' read -r games_played best_game <<< "$user_stats"
	echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0
echo "Guess the secret number between 1 and 1000:"

while read -r guess; do
	((number_of_guesses++))
	if ! [[ $guess =~ ^[+-]?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
		continue
	fi

	if [[ $guess == -* ]]; then
		echo "It's higher than that, guess again:"
		continue
	fi

	guess_number=${guess#+}
	while [[ ${#guess_number} -gt 1 && $guess_number == 0* ]]; do
		guess_number=${guess_number#0}
	done

	if [[ ${#guess_number} -lt ${#secret_number} ]] || { [[ ${#guess_number} -eq ${#secret_number} ]] && [[ $guess_number < $secret_number ]]; }; then
		echo "It's higher than that, guess again:"
	elif [[ ${#guess_number} -gt ${#secret_number} ]] || { [[ ${#guess_number} -eq ${#secret_number} ]] && [[ $guess_number > $secret_number ]]; }; then
		echo "It's lower than that, guess again:"
	else
		echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
		$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$username_escaped', 1, $number_of_guesses) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = LEAST(users.best_game, EXCLUDED.best_game);" >/dev/null
		break
	fi
done
