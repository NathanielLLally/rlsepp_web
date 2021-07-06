var term = new Terminal({
	cursorBlink: "block",
	rows: 40,
	cols: 180,
});
//const ws = new WebSocket("ws://localhost:3000", "echo-protocol");
var curr_line = "";
var entries = [];
term.open(document.getElementById("terminal"));
let PS1 = `\x1b[1;34mrpc\x1b[1;32m->\x1b[1;36mexecute\x1b[1;32m->\x1b[1;33mskyhawk\x1b[1;37m $ `;
term.write(PS1);

term.prompt = () => {
	if (curr_line) {
		let data = { method: "command", command: curr_line };
		window.wsRPC({cmd: curr_line, transaction_tag: $('#transaction_tag').html()});
//		ws.send(JSON.stringify(data));
	}
};
term.prompt();

/*
// Receive data from socket
ws.onmessage = msg => {
	term.write("\r\n" + JSON.parse(msg.data).data);
	curr_line = "";
};
*/
term.on("key", function(key, ev) {
		//Enter
		if (ev.keyCode === 13) {
		if (curr_line) {
		entries.push(curr_line);
		term.write("\r\n");
		term.prompt();
		}
		} else if (ev.keyCode === 8) {
		// Backspace
		if (curr_line) {
		curr_line = curr_line.slice(0, curr_line.length - 1);
		term.write("\b \b");
		}
		} else {
		curr_line += key;
		term.write(key);
		}
		});

// paste value
term.on("paste", function(data) {
		curr_line += data;
		term.write(data);
		});
