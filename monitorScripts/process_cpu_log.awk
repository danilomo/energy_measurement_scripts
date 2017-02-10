/Average/ && $2 == "all" {
	
	printf "%.0f ", time >> filename  "_all.txt";

	for(i=3;i<=NF;++i) printf "%.2f ", $i >> filename  "_all.txt";	
	
	printf "\n" >> filename  "_all.txt";
}

/Average/ && $2 != "CPU" && $2 != "all"  {

	printf "%.0f ", time >> filename  "_" $2 ".txt";

	for(i=3;i<=NF;++i) printf "%.2f ", $i >> filename  "_" $2 ".txt";
	
	printf "\n" >> filename  "_" $2 ".txt";
}
