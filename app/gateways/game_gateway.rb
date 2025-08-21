# frozen_string_literal: true

class GameGateway
  GAMES_ONLY = "version_parent = null & (category = 0 | category = 4)"
  GAME_FIELDS = "id, name, first_release_date, platforms.name, cover.url, created_at, updated_at"

  # Initializes a new GameGateway instance
  # Sets up the IGDB client with credentials from AppConfig
  def initialize
    @client = IGDB::Client.new(AppConfig.get("IGDB.CLIENT"), AppConfig.get("IGDB.SECRET"))
  end

  # Finds a game by its IGDB ID
  # @param id [Integer] The IGDB ID of the game to find
  # @param fields [Hash] The fields to retrieve, defaults to all fields
  # @return [Hash] The game data
  def find_by_id(id, fields = {fields: "*"})
    @client.id(id, fields)
  end

  # Searches for games matching the given query
  # @param query [String] The search query
  # @param fields [Hash] The fields to retrieve, defaults to all fields
  # @return [Array<Hash>] Array of game data matching the search
  def search(query, fields = {fields: "*"})
    @client.search(query, fields)
  end

  # Fetches games from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The maximum number of games to retrieve, defaults to 10
  # @param sort [String] The sorting criteria, defaults to "first_release_date desc"
  # @param where [String, nil] Additional filter conditions, defaults to nil
  # @return [Array<Hash>] Array of game data
  def fetch_games(fields: "*", limit: 10, sort: "first_release_date desc", where: nil)
    params = {fields: fields, limit: limit, sort: sort}
    params[:where] = where unless where.nil?
    @client.endpoint = "games"
    @client.get(params)
  end

  # Fetches popular game IDs from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to "game_id,value,popularity_type"
  # @param limit [Integer] The maximum number of games to retrieve, defaults to 10
  # @param sort [String] The sorting criteria, defaults to "value desc"
  # @param popularity_type [Integer] The type of popularity to filter by, defaults to 5
  # @return [Array<Hash>] Array of popular game data
  def fetch_popular_game_ids(fields: "game_id,value,popularity_type", limit: 10, sort: "value desc", popularity_type: 5)
    params = {fields: fields, limit: limit, sort: sort, where: "popularity_type = #{popularity_type}"}
    @client.endpoint = "popularity_primitives"
    @client.get(params)
  end

  # Fetches all games from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @return [Array<Hash>] Array of all games data
  def fetch_all_games(fields: GAME_FIELDS, limit: 500, sort: "id asc", offset: 0)
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

  # Fetches all games updated since a specified date (including new ones), streaming them in batches
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @param date [DateTime] Games updated after or on this date are fetched and updated, defaults to latest updated_at, falls back to 1 week ago
  # @return [Array<Hash>] Array of updated games data batch
  def each_updated_game_batch(fields: GAME_FIELDS, limit: 500, sort: "id asc", date: Game.maximum(:updated_at) || 1.week.ago)
    # This allows for calling without a block
    return enum_for(:each_updated_game_batch, fields:, limit:, sort:, date:) unless block_given?

    offset = 0
    where = "#{GAMES_ONLY} & updated_at >= #{date.to_i}"
    total = fetch_game_count(where: where)

    puts "Total games to fetch: #{total} (updated since #{date})"

    while offset < total
      batch = fetch_batch_of_games(fields: fields, limit: limit, sort: sort, offset: offset, where: where)
      yield batch

      offset += limit
    end
  end

  # Fetches a batch of games starting from the specified offset
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @return [Array<Hash>] Array of games data for the retrieved batch
  def fetch_batch_of_games(fields: GAME_FIELDS, limit: 500, sort: "id asc", offset: 0, where: GAMES_ONLY)
    @client.endpoint = "games"

    puts "Starting fetch of games from offset #{offset}..."

    params = {fields: fields, limit: limit, sort: sort, offset: offset, where: where}
    games = @client.get(params)

    puts "Fetched #{games.count} games"
    games
  end

  # Gets the total count of games matching the specified conditions
  # @param where [String, nil] Additional filter conditions, defaults to nil
  # @return [Integer] The count of games
  def fetch_game_count(where: nil)
    old_endpoint = @client.endpoint
    @client.endpoint = "games/count"
    where = if where.present?
      "#{GAMES_ONLY} & #{where}"
    else
      GAMES_ONLY
    end
    params = {where: where}

    count = @client.get(params).count

    @client.endpoint = old_endpoint
    count
  end
end
