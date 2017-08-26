class AddResultRefToEvents < ActiveRecord::Migration[5.0]
  def change
    add_reference :events, :result, foreign_key: true
  end
end
