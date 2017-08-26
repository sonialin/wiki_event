class AddIndexToResults < ActiveRecord::Migration[5.0]
  def change
    add_index :results, :queried_date
  end
end
