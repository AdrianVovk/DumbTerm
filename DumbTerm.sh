#!/usr/bin/env zsh
clear
w=50
h=16

export NEWT_COLORS='root=,black'

func error() {
	NEWT_COLORS='root=,red' whiptail --msgbox $1 $h $w --title "Error"
}

########################################################################
# PROFILES
########################################################################

func createConfig() {
        mkdir -p $1

        whiptail --inputbox "Host" $h $w `cat $1/ip` --title "Profile Setup" 0&> $1/ip || return 1
        whiptail --inputbox "Port" $h $w `cat $1/port`  --title "Profile Setup" 0&> $1/port || return 1
        whiptail --inputbox "Username" $h $w `cat $1/user` --title "Profile Setup" 0&> $1/user || return 1

		if [ ! -f $1/is-tun ]; then; default="--defaultno"; fi
		whiptail --yesno "Connect to this device by tunneling through another host?" $h $w $default --title "Setup" && unset default
		if [ $? = 0 ]; then # yes = 0
			whiptail --inputbox "Host" $h $w `cat $1/tun-ip` --title "Tunnel Setup" 0&> $1/tun-ip || return 1
	        whiptail --inputbox "Port" $h $w `cat $1/tun-port` --title "Tunnel Setup" 0&> $1/tun-port || return 1
	        whiptail --inputbox "Username" $h $w `cat $1/tun-user` --title "Tunnel Setup" 0&> $1/tun-user || return 1

			if [ ! -f $1/tun-pass-same ]; then; default="--defaultno"; fi
			whiptail --yesno "Does your tunnel have the same password as your primary host?" $h $w $default --title "Tunnel Setup" && unset default
			if [ $? = 0 ]; then; touch $1/tun-pass-same; fi

	        touch $1/is-tun
		fi

		if [ $1 != /tmp/term ]; then
			if [ -f $1/name ]; then
				DEFAULT=`cat $1/name`
			else
				DEFAULT="`cat $1/user`@`cat $1/ip`:`cat $1/port`"
			fi
			whiptail --inputbox "Name" $h $w $DEFAULT --title "Profile Setup" 0&> $1/name || return 1
		fi
}

func createProfile() {
	ID=$RANDOM$RANDOM
	createConfig ~/.config/term/$ID/
	echo "$ID" >> ~/.config/term/profiles
}

func pickProfile() {
	list=(`cat ~/.config/term/profiles`); profiles=(); for ID in $list; do; profiles+=($ID "`cat ~/.config/term/$ID/name`"); done
	PROFILE=$(whiptail --menu "Pick a profile" $h $w 10 ${profiles[@]} --clear --notags --title "Profiles" 3>&1 1>&2 2>&3) || return 1
}

########################################################################
# X11
########################################################################

func runXCommand() {
   echo $1 >> ~/.xinitrc # Add the command to xinitrc
   xinit # Start the session
   head -n -1 ~/.xinitrc | sponge ~/.xinitrc # Remove the command from xinitrc
}

########################################################################
# LOGIN
########################################################################

#TODO Make pass append strings (for different auth methods)

func pass() {
	SSHPASS=$(whiptail --passwordbox $1 $h $w --title "Login" --nocancel 3>&1 1>&2 2>&3)
}

func login() {
	if [ $1 != /tmp/term ]; then
		DIR=$HOME/.config/term/$1
	else
		DIR=$1
	fi
	if [ ! -f $DIR/is-tun ]; then
		loginStandard $DIR $2 $3
	else
		loginTunnel $DIR $2 $3
	fi
}

func loginStandard() {
	if [ $1 != /tmp/term ]; then
		NAME=`cat $1/name`
	else
		NAME=`cat $1/ip`
	fi
	pass "Password for $NAME"
   COMMAND="sshpass -p $SSHPASS ssh -t -X `cat $1/user`@`cat $1/ip` -p `cat $1/port` $2"
   if [ "$3" = "x11" ]; then
      # TODO X
      runXCommand $COMMAND
   else
    $COMMAND || error "Failed to connect"
   fi
#	SSH="ssh -t `cat $1/user`@`cat $1/ip` -p `cat $1/port` $2"
#	sshpass -p $SSHPASS $SSH || if [ $? -eq 6 ]; then; error "Please try again"; $SSH; else; error "Failed to connect"; fi
	unset SSHPASS
}

func loginTunnel() {
	if [ ! -f $1/tun-pass-same ]; then
		pass "Password for tunnel (`cat $1/tun-ip`)"
		TUNPASS=$SSHPASS
		pass "Password for `cat $1/name`"
		CHILDPASS=$SSHPASS
	else
		pass "Password for `cat $1/name`"
		TUNPASS=$SSHPASS
		CHILDPASS=$SSHPASS
	fi
#	ERROR_CHECKER="if [ $? -eq 6 ]; then; "; ERROR_CHECKER_END="; else; return 255; fi"
#	CHILD_SSH="ssh -t `cat $1/user`@`cat $1/ip` -p `cat $1/port` $2"
#	TUN_SSH="ssh -t `cat $1/tun-user`@`cat $1/tun-ip` -p `cat $1/tun-port` \"sshpass -p $CHILDPASS $CHILD_SSH || eval $ERROR_CHECKER $CHILD_SSH $ERROR_CHECKER_END\""
#   ( sshpass -p "$TUNPASS" $TUN_SSH || eval $ERROR_CHECKER $TUN_SSH $ERROR_CHECKER_END ) || error "Failed to connect"
	COMMAND="sshpass -p "$TUNPASS" ssh -t `cat $1/tun-user`@`cat $1/tun-ip` -p `cat $1/tun-port` \"sshpass -p $CHILDPASS ssh -t `cat $1/user`@`cat $1/ip` -p `cat $1/port` $2\""
	if [ $3 = "x11" ]; then
	   error "Tunnels are currently unsupported with X"
	else
		$COMMAND || error "Failed to connect"
	fi
	unset TUNPASS CHILDPASS SSHPASS #TUN_SSH
}

########################################################################
# MAIN
########################################################################

func menu() {
	clear
	defaultName=`ID=$(cat ~/.config/term/defaultProfile);cat ~/.config/term/$ID/name`
	whiptail --menu "" $h $w 6 "login" "Login ($defaultName)" \
		"run" "Run a command on $defaultName" \
		"x11" "Run a graphical program" \
		"profiles" "All profiles" \
		"tmp" "One-time login" \
		"more" "Advanced" \
		--clear --notags --cancel-button "Shut Down" --title "Home" 0&> /tmp/start-option
	opt=`cat /tmp/start-option`
	case `cat /tmp/start-option` in
		"login")
			login `cat ~/.config/term/defaultProfile`
		menu ;;
		"run")
			COMMAND=$(whiptail --inputbox "Enter a command to run on $defaultName" $h $w `cat ~/.config/term/lastRun` --title "Run" 3>&1 1>&2 2>&3)
			echo $COMMAND > ~/.config/term/lastRun
			login `cat ~/.config/term/defaultProfile` $COMMAND && \
				echo -n "-------------------- DONE. PRESS ANY KEY TO EXIT. --------------------"; read -k1 -s
		menu ;;
		"x11")
			COMMAND=$(whiptail --inputbox "Enter a graphical program to run on $defaultName" $h $w `cat ~/.config/term/lastX11` --title "Run GUI" 3>&1 1>&2 2>&3)
			echo $COMMAND > ~/.config/term/lastX11
			pickProfile && login $PROFILE $COMMAND x11
		menu ;;
		"profiles")
			pickProfile && login $PROFILE
		menu ;;
		"tmp")
			createConfig /tmp/term "" "22" "" && cat /tmp/term/ip > /tmp/term/name && login /tmp/term
			rm -rf /tmp/term
		menu ;;
		"more")
			advanced
		menu ;;
	esac
}

func advanced() {
	clear
	whiptail --menu "" $h $w 10 "new" "Create a new profile" \
		"edit" "Edit a profile" \
		"chdef" "Change the default profile" \
		"del" "Delete a profile" \
		"net" "Configure Network" \
		"net-login" "Log into the network" \
		"sh" "Log in locally" \
		"reset" "Reset" \
		"about" "About" \
		"reload" "Reload this tool" \
		--clear --notags --cancel-button "Back" --title "Advanced" 0&> /tmp/more-option
	case `cat /tmp/more-option` in
		"new")
			createProfile
		advanced ;;
		"edit")
			pickProfile && createConfig ~/.config/term/$PROFILE
		advanced ;;
		"chdef")
			pickProfile && echo $PROFILE > ~/.config/term/defaultProfile && sleep 0.5
		advanced ;;
		"del")
			pickProfile && ID=$PROFILE && \
			NAME=`cat ~/.config/term/$ID/name` && \
			whiptail --yesno "Are you sure you want to delete this profile ($NAME)?" $h $w --title "Confirmation"
			if [ $? != 0 ]; then; return; fi
			sed -ie "/$ID/d" ~/.config/term/profiles
			rm -rf ~/.config/term/$ID
		advanced ;;
		"net")
			echo "Please wait..."
			nmtui
		advanced ;;
		"net-login")
			echo "Please wait..."
			links2 -anonymous "http://gstatic.com/generate_204/"
		advanced ;;
		"sh")
			/usr/bin/env login || { whiptail --msgbox "You do not have permission to run \`login\`. Starting a Bash session" $h $w --title "Error"; bash }
		advanced ;;
		"reset")
			whiptail --yesno "Are you sure you want to reset to default settings?" $h $w --title "Confirmation"
			if [ $? = 0 ]; then # yes = 0
				echo "Please wait..."
				rm -rf ~/.config/term
				whiptail --msgbox "Done. You will be prompted to set new default values" $h $w --title "Reset"

				clear
				echo "Please wait..."
				sleep 0.2
				echo "Restarting..."
				sleep 1
				exit 0
			else
				whiptail --msgbox "Aborted." $h $w --title "Reset"
			fi
		advanced ;;
		"about")
			whiptail --yesno "DumbTerm is a little script that can be run at startup to turn your device in a pseudo-dumb-terminal." $h $w --title "About" --yes-button "Update" --no-button "Ok"
			if [ $? = 0 ]; then
			   cd `cat /opt/DumbTermInstall` && git pull && exit 0
			fi
		advanced ;;
		"reload")
			exit 0
		advanced ;;
	esac
}

if [ ! -d ~/.config/term ]; then
	whiptail --msgbox "It is necessary to input some default values for this tool." $h $w --title "Welcome"
	createProfile; echo $ID > ~/.config/term/defaultProfile
fi
menu # Start the script
if [ $UID = 0 ]; then; shutdown now; fi # Shutdown only if we are running from root, which is most likely when running from systemd