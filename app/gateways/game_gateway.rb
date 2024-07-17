# frozen_string_literal: true

class GameGateway
  def initialize
    @client = IGDB::Client.new(ENV["IGDB_CLIENT"], ENV["IGDB_SECRET"])
  end

  def find_by_id(id, fields = {fields: "*"})
    @client.id(id, fields)
  end

  def search(query, fields = {fields: "*"})
    @client.search(query, fields)
  end

  def get_games(fields: "*", limit: 10, sort: "first_release_date desc", where: nil)
    params = {fields: fields, limit: limit, sort: sort}
    params[:where] = where unless where.nil?
    @client.endpoint = "games"
    @client.get(params)
  end

  def get_popular_game_ids(fields: "game_id,value,popularity_type", limit: 10, sort: "value desc", popularity_type: 1)
    params = {fields: fields, limit: limit, sort: sort, where: "popularity_type = #{popularity_type}"}
    @client.endpoint = "popularity_primitives"
    @client.get(params)
  end

  def get_all_games(fields: "*", limit: 500, sort: "id asc", offset: 0)
    @client.endpoint = "games/count"
    count = @client.get.count

    @client.endpoint = "games"
    games = []

    while games.count < count
      puts "Starting fetch of games from offset #{offset}..."

      params = { fields: fields, limit: limit, sort: sort, offset: offset}
      games.concat @client.get(params)

      offset += [limit, count - offset].min

      puts "Fetched #{games.count} games out of #{count}"
    end
    games
  end

end
