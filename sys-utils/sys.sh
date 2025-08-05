# power off
gpoff(){ sudo poweroff $@ }

# reboot
grbt(){ sudo reboot $@ $@ }

# Hibernate
ghib(){ sudo systemctl hibernate $@ }