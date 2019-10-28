#!/bin/bash


#                    "Often, I load up the weather app on my phone, and the weather information simply does not load.
#		      The only information I will see in the temperature slot is "--", even when I'm connected to wi-fi!
#		      In addition, a significant part of my morning is figuring out what to wear. I would like someone
#		      (or some program) to tell me what to wear based on the temperature. To do this, I am using the 
#		      OpenWeatherMap API. It is free to sign up for a limited version."
#  		      
# The first segment prompts the user for their location, as I wanted to be able to use my script in other locations.
# This version of the curl API pull takes in the name of a city, so I prompt the user for a city name. I also prompt
# the user for a measurement type, f for Fahrenheit or c for Celsius.
# This is done using the read command, which reads a single line from the terminal input.
# The flag used is -p, which allows for a prompt to be sent to the user. My prompts indicate what input I want from the user.
# Both inputs are then set to variables, $LOCATION && $MEASURE

read -p "Enter a city: " LOCATION
read -p "Enter a measurement system [f][c]: " MEASURE

# Then, I set the default measurement tool to imperial, which represents Fahrenheit.
# I use an if statement to check the input of $MEASURE, changing $default_measure to metric (Celsius) ONLY if necessary.

default_measure="imperial"
if [ "$MEASURE" = "c" ]
then
	default_measure="metric"
fi 

# Here, I set the strings used later to represent the OpenWeatherMap api key and the e-mail address that information will
# be sent to. 
# NOTE!: Here, you must input a valid OpenWeatherMap API key for 'api_key' and a valid e-mail address for 'address'.
# 	 These variables constitute the API key that is used to retrieve information, and the e-mail that will receive a clothing recommendation.

api_key=""
address=""

# Next, I determine a file path for where I want to store the JSON data variable info that I receive from the API.
# I then use the touch command to create the file specified in $wthr_file

wthr_file="/tmp/wthr-$LOCATION-info.json"
touch $wthr_file

# Here, I use the curl command to retrieve information from the OpenWeatherMap API.
# The link that I use curl with needs to know certain parameters. In this case, city, unit of measurement, and API key.
# The flag used is -s, which mutes the retrieval progress bar that is shown by default with curl.
# I then use echo to write this information to my pre-determined $wthr_file directory.
# This file was absolutely necessary for testing, as I could use the cat command to see what data variables were available
# for me to display using the script
# Example:
# -bash-4.2$ cat $wthr_file
#
# This would print, in a few lines, all of the data variables. This information is also available on the OpenWeatherMap website,
# but I wanted to see if my script was actually writing to the file.

weather=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$LOCATION&units=$default_measure&appid=$api_key")
echo $weather > $wthr_file

# Now, I write a header to the user using the input location and the echo command.
# The flag used is -e, which enables escape characters

echo -e "\nToday's Weather Report for $LOCATION \n"

# With these next lines, I store information from the API in variable that I can use within echo commands later.
# The command used to parse the file is jq, which refers to the standard bash JSON processer.

temp=$(echo $weather | jq .main.temp)
temp_max=$(echo $weather | jq .main.temp_max)
temp_min=$(echo $weather | jq .main.temp_min)
descr=$(echo $weather | jq .weather[].description)
wthr_type=$(echo $weather | jq .weather[].main)

# Now, it is time to give all of the data back to the user. I have decided that the most important things to display
# are current, min and max temp, current weather, and a short description of the current weather, which are all 
# available using OpenWeatherMap.

echo -e "Current Temperature: $temp degrees $MEASURE \n"
echo -e "Max. Temp: $temp_max deg $MEASURE      Min. Temp: $temp_min deg $MEASURE \n"
echo -e "General Weather: $wthr_type \n"
echo -e "Description: $descr \n"

# Here, I convert the floating point variable that is $temp into an integer so that I can use comparator commands on it.

int_temp=${temp/.*}

# Next, I wanted to build the clothing recommendation portion of the script. However, I am only familiar with the ballpark
# temperatures for Fahrenheit. Therefore, the command is simply a nested if-statement that first checks if Fahrenheit data is
# being used, and then sets the appropriate recommendation based on the current temperature.

if [ "$MEASURE" = "f" ]
then
	if [ $int_temp -ge 80 ]
	then
		clothing_rec="It's warm outside today. Wear a T-shirt, shorts, and make sure to hydrate and keep cool."
	elif [ $int_temp -ge 60 ] && [ $int_temp -lt 80 ]
	then
		clothing_rec="It's a moderate temperature outside. Consider wearing a T-shirt and some jeans, bring a jacket."
	elif [ $int_temp -ge 32 ] && [ $int_temp -lt 60 ]
	then
		clothing_rec="It's a bit chilly outside. Wear a long sleeve and warm pants. Don't forget to bring a jacket in case of rain."
	else
		clothing_rec="It's below freezing! Bring a thick jacket and be sure to stay warm."
	fi
fi

# These echo commands inform the user of the recommendation, and the fact that they will receive an e-mail at the specified
# e-mail address.

echo -e "Recommendation: $clothing_rec \n"
echo -e "This recommendation will be sent to your e-mail inbox at: $address\n" 

# This line sends the user an e-mail at the previously specified address (see above)
# The command used is mailx, which sends an e-mail to a specified address.
# The flag used is -s, which allows for a subject line in the e-mail
# <<< allows the script to write the text of the e-mail in the command line.

mailx -s "Today's Clothing Recommendation for: $LOCATION" $address <<<$clothing_rec

# Finally, the last step is to delete the file storing the current weather information.
# The command used is rm, which deletes the specified directory from the command line.

rm $wthr_file

# ================== END ==================
