exports.index = (req, res) ->
  res.render "index",
    title: "Express"

exports.game = (req, res) ->
  res.render "game",
    title: "The Game"
