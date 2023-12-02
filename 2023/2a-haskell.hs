import Data.Text as Text (Text, drop, pack, split, strip, unpack)
import System.Environment (getArgs)

data Cubes = Cubes {red :: Integer, green :: Integer, blue :: Integer} deriving (Show)

zeroCubes :: Cubes
zeroCubes = Cubes 0 0 0

redCubes :: Integer -> Cubes
redCubes red = Cubes red 0 0

greenCubes :: Integer -> Cubes
greenCubes green = Cubes 0 green 0

blueCubes :: Integer -> Cubes
blueCubes blue = Cubes 0 0 blue

maxCubes :: Cubes -> Cubes -> Cubes
(Cubes r1 g1 b1) `maxCubes` (Cubes r2 g2 b2) =
  Cubes (max r1 r2) (max g1 g2) (max b1 b2)

data Game = Game {id :: Integer, cubes :: Cubes} deriving (Show)

parseCube :: Text -> Cubes
parseCube cube =
  let [number, colour] = split (== ' ') cube
   in case unpack colour of
        "red" -> redCubes
        "green" -> greenCubes
        "blue" -> blueCubes
        $ read
        $ unpack number

parseSet :: Text -> Cubes
parseSet set =
  foldr (maxCubes . parseCube) zeroCubes $
    map strip $
      split (== ',') set

parseLine :: Text -> Game
parseLine line =
  let [idPrefix, sets] = split (== ':') line
      [_, idNumber] = split (== ' ') idPrefix
   in Game (read $ unpack idNumber) $
        foldr (maxCubes . parseSet . strip) zeroCubes $
          split (== ';') sets

possible :: Game -> Bool
possible (Game _ (Cubes r g b)) =
  r <= 12 && g <= 13 && b <= 14

main :: IO ()
main = do
  file <- getArgs >>= readFile . head
  print $ sum $ map (\(Game id _) -> id) $ filter possible $ map (parseLine . pack) $ lines file