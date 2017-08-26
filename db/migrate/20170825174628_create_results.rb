class CreateResults < ActiveRecord::Migration[5.0]
  def change
    create_table :results do |t|
      t.datetime :queried_date

      t.timestamps
    end
  end
end
