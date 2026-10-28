package memoir

import "gxb.local/backend/v2/internal/domain/campaign"

const (
	Road int64 = iota
	Wall
	Guardian
	Monster
	Player
	BigBox
	SmallBox
	BigBoxOpened
	SmallBoxOpened
	Endpoint
)

const BoardColumns = 9
const BoardRows = 6
const BoardCells = BoardColumns * BoardRows
const InitialPosition = 1
const FinalPosition = BoardCells
const GuardianPosition = FinalPosition - 1

type Board struct {
	Cells       []int64       `json:"cells"`
	Open        map[int]int64 `json:"open"`
	Enemies     map[int]int64 `json:"enemies"`
	Position    int           `json:"position"`
	GuardianWon bool          `json:"guardian_won"`
}

func (catalog Catalog) NewBoard(girlIdentifier int64, floorNumber int, opponents []int64, source campaign.Uniform) (Board, error) {
	girl, found := catalog.Girl(girlIdentifier)
	if !found || floorNumber < 1 || floorNumber > len(catalog.Floors) || len(opponents) == 0 || source == nil {
		return Board{}, ErrInvalid
	}
	floor := catalog.Floors[floorNumber-1]
	board := Board{Cells: make([]int64, BoardCells), Open: map[int]int64{}, Enemies: map[int]int64{}, Position: InitialPosition}
	for position := 1; position <= BoardCells; position++ {
		board.Open[position] = 0
	}
	board.Cells[FinalPosition-1], board.Cells[GuardianPosition-1] = Endpoint, Guardian
	board.Enemies[GuardianPosition] = floor.Bosses[source.Uniform(uint64(len(floor.Bosses)))]
	positions := []int{}
	for position := 2; position < GuardianPosition; position++ {
		row, column := (position-1)/BoardColumns+1, (position-1)%BoardColumns+1
		reservedRoad := row%2 == 0 || column == 1 || column == BoardColumns || position == 2
		if reservedRoad {
			continue
		}
		positions = append(positions, position)
	}
	for index := len(positions) - 1; index > 0; index-- {
		other := int(source.Uniform(uint64(index + 1)))
		positions[index], positions[other] = positions[other], positions[index]
	}
	cursor := 0
	for _, count := range catalog.Counts {
		if count.Kind == Guardian {
			continue
		}
		amount := count.Bounds[0]
		if len(count.Bounds) == 2 {
			amount += int(source.Uniform(uint64(count.Bounds[1] - amount + 1)))
		}
		if cursor+amount > len(positions) {
			return Board{}, ErrUnavailable
		}
		for offset := 0; offset < amount; offset++ {
			position := positions[cursor]
			cursor++
			board.Cells[position-1] = count.Kind
			if count.Kind == Monster {
				pool := girl.Fights[floorNumber-1]
				board.Enemies[position] = pool[source.Uniform(uint64(len(pool)))]
			}
			if count.Kind == Player {
				board.Enemies[position] = opponents[source.Uniform(uint64(len(opponents)))]
			}
		}
	}
	board.Reveal(InitialPosition)
	return board, board.Validate()
}

func (board Board) Validate() error {
	if len(board.Cells) != BoardCells || board.Position < 1 || board.Position > BoardCells || board.Open == nil || board.Enemies == nil {
		return ErrUnavailable
	}
	if board.Cells[FinalPosition-1] != Endpoint || board.Cells[InitialPosition-1] != Road || board.GuardianWon != (board.Cells[GuardianPosition-1] == Road) || !board.GuardianWon && board.Cells[GuardianPosition-1] != Guardian {
		return ErrUnavailable
	}
	for index, kind := range board.Cells {
		if kind < Road || kind > Endpoint {
			return ErrUnavailable
		}
		if (kind == Guardian || kind == Monster || kind == Player) && board.Enemies[index+1] == 0 {
			return ErrUnavailable
		}
	}
	for position, value := range board.Open {
		if position < 1 || position > BoardCells || value < 0 || value > 1 {
			return ErrUnavailable
		}
	}
	if !board.walkable(board.Position) {
		return ErrUnavailable
	}
	return nil
}

func neighbors(position int) []int {
	result := []int{}
	if position < 1 || position > BoardCells {
		return result
	}
	column := (position - 1) % BoardColumns
	if column > 0 {
		result = append(result, position-1)
	}
	if column < BoardColumns-1 {
		result = append(result, position+1)
	}
	if position > BoardColumns {
		result = append(result, position-BoardColumns)
	}
	if position <= BoardCells-BoardColumns {
		result = append(result, position+BoardColumns)
	}
	return result
}

func (board Board) walkable(position int) bool {
	if position < 1 || position > len(board.Cells) {
		return false
	}
	kind := board.Cells[position-1]
	return kind == Road || kind == Endpoint && board.GuardianWon
}
func (board Board) reachable() map[int]bool {
	visited := map[int]bool{board.Position: true}
	queue := []int{board.Position}
	for index := 0; index < len(queue); index++ {
		for _, next := range neighbors(queue[index]) {
			if !visited[next] && board.walkable(next) {
				visited[next] = true
				queue = append(queue, next)
			}
		}
	}
	return visited
}
func (board Board) CanInteract(position int) bool {
	if position < 1 || position > len(board.Cells) {
		return false
	}
	reachable := board.reachable()
	if reachable[position] {
		return true
	}
	for _, adjacent := range neighbors(position) {
		if reachable[adjacent] {
			return true
		}
	}
	return false
}
func (board *Board) Reveal(position int) {
	board.Open[position] = 1
	for _, adjacent := range neighbors(position) {
		board.Open[adjacent] = 1
	}
}
func (board *Board) SaveMap(position int, opened []int) error {
	if board.Validate() != nil {
		return ErrUnavailable
	}
	reachable := board.reachable()
	if !reachable[position] {
		return ErrRefused
	}
	allowed := map[int]bool{}
	for cell := range reachable {
		allowed[cell] = true
		for _, adjacent := range neighbors(cell) {
			allowed[adjacent] = true
		}
	}
	seen := map[int]bool{}
	for _, cell := range opened {
		if !allowed[cell] || seen[cell] {
			return ErrInvalid
		}
		seen[cell] = true
	}
	board.Position = position
	for _, cell := range opened {
		board.Open[cell] = 1
	}
	board.Reveal(position)
	return nil
}
func (board *Board) ClearEnemy(position int) error {
	if !board.CanInteract(position) {
		return ErrRefused
	}
	kind := board.Cells[position-1]
	if kind != Guardian && kind != Monster && kind != Player {
		return ErrRefused
	}
	if kind == Guardian {
		board.GuardianWon = true
	}
	board.Cells[position-1] = Road
	board.Open[position] = 1
	return nil
}
func (board *Board) OpenBox(position int) (int, error) {
	if !board.CanInteract(position) {
		return 0, ErrRefused
	}
	kind := board.Cells[position-1]
	if kind == BigBox {
		board.Cells[position-1] = BigBoxOpened
		board.Open[position] = 1
		return 0, nil
	}
	if kind == SmallBox {
		board.Cells[position-1] = SmallBoxOpened
		board.Open[position] = 1
		return 1, nil
	}
	return 0, ErrRefused
}
func (board Board) CanExit(position int) bool {
	return position == FinalPosition && board.GuardianWon && board.CanInteract(position)
}
