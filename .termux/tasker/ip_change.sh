#!/data/data/com.termux/files/usr/bin/env bash

config="$HOME/.ssh/config"
hostname="$1"; shift
words=($@)

scrape_ip()
{
	for word in ${words[@]}
	do
		ip_reg="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
		[[ "$word" =~ $ip_reg ]] || continue

		ip=$word; break
	done
}

main()
{
	while read line
	do
		[[ $foundhn == 1 && $line =~ "HostName" ]] &&
			line="HostName	$ip"

		[[ $line =~ $hostname ]] && ((foundhn=1)) || ((foundhn=0))

		lines+=("$line" )

	done < "$config"
}

scrape_ip
main || exit 1

[[ $ip ]] || exit 1
printf '%s\n' "${lines[@]}" > $config
