module main

import gg
import gx

const (
	win_width      = 200
	win_height     = 240
	block_size_x   = win_width / 3
	block_size_y   = win_height / 3
	start_y        = 0
	start_x        = 0
	no_mark        = -1
	p1_mark        = 1
	p2_mark        = 2
	// pairs of other tiles that must have been captured to win this click
	winning_clicks = [
		[[1, 2], [3, 6], [4, 8]], // top-left wins
		[[0, 2], [4, 7]], // top middle
		[[0, 1], [5, 8], [4, 6]], // top right
		[[0, 6], [4, 5]], // middle left
		[[0, 8], [1, 7], [2, 6], [3, 5]], // middle
		[[3, 4], [2, 8]], // middle right
		[[0, 3], [4, 2], [7, 8]], // bottom left
		[[6, 8], [1, 4]], // bottom middle
		[[6, 7], [0, 4], [2, 5]], // bottom right
	]
)

struct App {
mut:
	gg              &gg.Context
	board           []int = []int{len: 9, init: no_mark}
	player_mark     int   = p1_mark
	running         bool  = true
	remaining_moves int   = 9
	game_won        bool
}

fn init(mut app App) {
}

fn (app &App) block(ndx int) (f32, f32) {
	temp_x := ndx % 3
	temp_y := if ndx > 5 {
		2 * block_size_y + start_y
	} else if ndx > 2 {
		block_size_y + start_y
	} else {
		start_y
	}

	block_x := start_x + temp_x * block_size_x
	block_y := temp_y

	return block_x, block_y
}

fn (mut app App) draw_board() {
	for i in 0 .. app.board.len {
		piece := app.board[i]

		block_x, block_y := app.block(i)

		color := if piece == no_mark {
			gx.white
		} else if piece == p1_mark {
			gx.red
		} else {
			gx.blue
		}

		app.gg.draw_rect_filled(block_x, block_y, block_size_x, block_size_y, color)
		app.gg.draw_rect_empty(block_x, block_y, block_size_x, block_size_y, gx.black)
		app.gg.draw_text(int(block_x) + 5, int(block_y) + 5, i.str())
	}
}

fn (mut app App) draw_win() {
	if app.running || !app.game_won {
		return
	}
	app.gg.draw_text(start_x + block_size_x, start_y + block_size_y, 'Player $app.player_mark Won!',
		size: 22, color: gx.green)
}

fn (mut app App) draw_tie() {
	if app.running || app.game_won {
		return
	}

	app.gg.draw_text(start_x + block_size_x, start_y + block_size_y, 'Tie Game!',
		size: 22
		color: gx.green
	)
}

fn (mut app App) toggle_player() {
	app.player_mark = if app.player_mark == p1_mark {
		p2_mark
	} else {
		p1_mark
	}

	app.remaining_moves--
}

fn (mut app App) draw() {
	app.gg.begin()
	app.draw_board()
	app.draw_win()
	app.draw_tie()
	app.gg.end()
}

fn frame(mut app App) {
	app.draw()
}

fn click(x f32, y f32, button gg.MouseButton, mut app App) {
	if !app.running {
		return
	}
	for i in 0 .. app.board.len {
		if app.board[i] != no_mark {
			continue
		}

		block_x, block_y := app.block(i)

		// limit click to a column
		if x < block_x || x > block_x + block_size_x {
			continue
		}

		// find which cell within the column
		if y < block_y || y > block_y + block_size_y {
			continue
		}

		// mark cell with correct player info
		app.board[i] = app.player_mark

		mut has_won := false
		for winning_click in winning_clicks[i] {
			mut win_check := true
			for block_ndx in winning_click {
				win_check = win_check && app.board[block_ndx] == app.player_mark
			}

			if win_check {
				has_won = win_check
				break
			}
		}

		if has_won {
			app.game_won = true
			app.running = false

			return
		}

		if !has_won && app.remaining_moves == 1 {
			app.running = false

			return
		}

		app.toggle_player()

		break
	}
}

[no_console]
fn main() {
	mut app := &App{
		gg: 0
	}
	app.gg = gg.new_context(
		bg_color: gx.black
		width: win_width
		height: win_height
		// create_window: true
		window_title: 'Tic Tac Toe'
		init_fn: init
		click_fn: click
		frame_fn: frame
		user_data: app
		ui_mode: true
	)

	app.gg.run()
}
