#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

CREATE_RANDOM_NUM() {
  echo $((1 + $RANDOM % 1000))
}

CREATE_USER() {
  local USERNAME=$1
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")

  if [[ -z $INSERT_USER_RESULT ]]
  then
    return 1 
  else
    return 0
  fi
}

MAIN() {
  echo -e "\nEnter your username:" 
  read USERNAME

  USER_ID=$($PSQL "
    SELECT user_id 
    FROM users 
    WHERE username = '$USERNAME';
  ")

  if [[ -z $USER_ID ]]
  then
    CREATE_USER $USERNAME
    USER_ID=$($PSQL "
      SELECT user_id 
      FROM users 
      WHERE username = '$USERNAME';
    ")

    if [ $? -eq 0 ]
    then
      echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    else
      echo -e "\nInsert user into database failed..."
      exit 1
    fi
  else
    PLAYER_STATS=$($PSQL "
      SELECT COUNT(*), MIN(guess_attempts)
      FROM games
      WHERE user_id = $USER_ID
      GROUP BY user_id 
    ")
    GAMES_PLAYED=$(echo $PLAYER_STATS | sed 's/|.*//')
    MIN_GUESSES=$(echo $PLAYER_STATS | sed 's/.*|//')
    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $MIN_GUESSES guesses."
  fi

  RANDOM_NUM=$(CREATE_RANDOM_NUM)
  CURR_GUESS=0
  TOTAL_ATTEMPTS=0 
  
  echo -e "\nGuess the secret number between 1 and 1000:"

  while [ $CURR_GUESS -ne $RANDOM_NUM ]
  do
    read GUESS

    if ! [[ $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not an integer, guess again:"
      continue
    fi

    CURR_GUESS=$GUESS
    TOTAL_ATTEMPTS=$(( $TOTAL_ATTEMPTS + 1 ))

    if [ $CURR_GUESS -lt $RANDOM_NUM ] 
    then
      echo -e "\nIt's higher than that, guess again:"
    elif [ $CURR_GUESS -gt $RANDOM_NUM ]
    then
      echo -e "\nIt's lower than that, guess again:"
    fi
  done
  echo -e "\nYou guessed it in $TOTAL_ATTEMPTS tries. The secret number was $RANDOM_NUM. Nice job!"
  
  INSERT_GAMES_TABLE_RESULT=$($PSQL "
    INSERT INTO games(user_id, guess_attempts)
    VALUES ($USER_ID, $TOTAL_ATTEMPTS)
  ")
}

MAIN