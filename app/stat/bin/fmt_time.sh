path=$1
awk '{getDate="date -j -f \"%b %d %H:%M:%S\" \""$1" "$2" "$3"\" \"+%Y-%m-%dT%H:%M:%S+08:00\""
      while ( ( getDate | getline date ) > 0 ) { }
      close(getDate);
      print date,$4,$5,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24}' $path/stat.log > $path/tmp.log