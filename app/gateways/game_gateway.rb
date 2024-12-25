# frozen_string_literal: true

class GameGateway
  GAMES_ONLY = "version_parent = null & (category = 0 | category = 4)"

  def initialize
    @client = IGDB::Client.new(ENV.fetch("IGDB_CLIENT"), ENV.fetch("IGDB_SECRET"))
  end

  def find_by_id(id, fields = {fields: "*"})
    @client.id(id, fields)
  end

  def search(query, fields = {fields: "*"})
    @client.search(query, fields)
  end

  def fetch_games(fields: "*", limit: 10, sort: "first_release_date desc", where: nil)
    params = {fields: fields, limit: limit, sort: sort}
    params[:where] = where unless where.nil?
    @client.endpoint = "games"
    @client.get(params)
  end

  def fetch_popular_game_ids(fields: "game_id,value,popularity_type", limit: 10, sort: "value desc", popularity_type: 3)
    params = {fields: fields, limit: limit, sort: sort, where: "popularity_type = #{popularity_type}"}
    @client.endpoint = "popularity_primitives"
    @client.get(params)
  end

  def fetch_all_games(fields: "*", limit: 500, sort: "id asc", offset: 0)
    @client.endpoint = "games/count"
    count = fetch_game_count

    @client.endpoint = "games"
    games = []

    while offset < count
      puts "Starting fetch of games from offset #{offset}..."

      params = {fields: fields, limit: limit, sort: sort, offset: offset, where: GAMES_ONLY}
      games.concat @client.get(params)

      offset += limit

      puts "Fetched #{games.count} games out of #{count}"
    end
    games
  end

  def fetch_batch_of_games(fields: "*", limit: 500, sort: "id asc", offset: 0)
    @client.endpoint = "games"
    games = []

    puts "Starting fetch of games from offset #{offset}..."

    params = {fields: fields, limit: limit, sort: sort, offset: offset, where: GAMES_ONLY}
    games.concat @client.get(params)

    puts "Fetched #{games.count} games"
    games
  end

  def fetch_game_count
    old_endpoint = @client.endpoint
    @client.endpoint = "games/count"
    count = @client.get({where:GAMES_ONLY}).count
    @client.endpoint = old_endpoint
    count
  end

end
