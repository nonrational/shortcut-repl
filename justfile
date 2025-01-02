console:
	bundle exec console

serve:
	bundle exec rerun 'ruby server.rb'

lint:
	bundle exec standardrb --fix
