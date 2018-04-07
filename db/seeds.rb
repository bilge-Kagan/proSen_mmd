# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
# Procedures:
ActiveRecord::Base.connection.execute(IO.read('db/Procedure(s)/add_values_update.sql'))
ActiveRecord::Base.connection.execute(IO.read('db/Procedure(s)/calibrate_after_record_delete.sql'))
ActiveRecord::Base.connection.execute(IO.read('db/Procedure(s)/statistic_inits.sql'))
ActiveRecord::Base.connection.execute(IO.read('db/Procedure(s)/bound_init.sql'))
ActiveRecord::Base.connection.execute(IO.read('db/Procedure(s)/overflow_check.sql'))

# Triggers:
ActiveRecord::Base.connection.execute(IO.read('db/Trigger(s)/add_measurement.sql'))
ActiveRecord::Base.connection.execute(IO.read('db/Trigger(s)/add_sensor.sql'))
