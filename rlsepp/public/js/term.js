const term = new window.Terminal({
	cursorBlink: "block",
//	rows: 30,
//	cols: 180,
});
const fitAddon = new window.FitAddon.FitAddon();
term.loadAddon(fitAddon);
const parentHTML = document.getElementById("terminal");
term.open(parentHTML);
term.focus();
fitAddon.fit();


//const ws = new WebSocket("ws://localhost:3000", "echo-protocol");
var curr_line = "";
var paste = "";
var entries = [];
function values() {
  const items = [...entries];
  let index = items.length -1;

  return {
    [Symbol.iterator]() {
      return this;
    },
		first() {
  		index = -1;
			return this.next()
		},
		last() {
  		index = items.length;
			return this.previous()
		},

    next() {
      var item = items[index + 1];
      if (item) {
				index++;
        return {
          value: item,
          done: false
        };
      }
			index = items.length;
      return { done: true };
    },

    previous() {
      var item = items[index - 1];
      if (item) {
				index--;
        return {
          value: item,
          done: false
        };
      }
			index = -1;
      return { done: true };
    }
  };
}
let history = values();
let PS1 = `\x1b[1;34mrpc\x1b[1;32m->\x1b[1;36mexecute\x1b[1;32m->\x1b[1;33mskyhawk\x1b[1;37m $ `;
term.write(PS1);

let commands = ["clear", "history"];
term.prompt = () => {
	if (curr_line) {
    if (commands.indexOf(curr_line) > -1) {
			switch (curr_line) {
				case "clear":
			curr_line = "";
      term.clear();
			term.write(PS1);
					break;
				case "history":
	let it = values();
it.first();
					do {
let v = it.value;
						term.write("\r\n");
if (v) {
						term.write(v);
}
it.next();
} while (!it.done);
//					for (let e of entries) { }
		term.write("\r\n");
		term.prompt();
					break;
				default:
					break;
			}
    } else {
      let args = curr_line.split(' ');
      let cmd = args.shift();
	  	window.wsRPC({cmd: cmd, transaction_tag: $('#transaction_tag').html()},...args);
    }
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
term.onKey((e) => {
    const ev = e.domEvent;
    const printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey;
		//Enter
		if (ev.keyCode === 13) {
		if (curr_line) {
		entries.push(curr_line);
		history = values();
		term.write("\r\n");
		term.prompt();
		}
		} else if (ev.keyCode === 8) {
		// Backspace
		if (curr_line) {
		curr_line = curr_line.slice(0, curr_line.length - 1);
		term.write("\b \b");
		}
		} else if (ev.keyCode === 40) {  //down
      let prev = history.next();
			if (prev.value) {
				while(curr_line.length) {
					curr_line = curr_line.slice(0, curr_line.length - 1);
					term.write("\b \b");
				}
				curr_line = prev.value
	      term.write(curr_line)
			} else {
				
			}
		} else if (ev.keyCode === 38) {  //up

      let next = history.previous();
			if (next.value) {
				while(curr_line.length) {
					curr_line = curr_line.slice(0, curr_line.length - 1);
					term.write("\b \b");
				}
				curr_line = next.value
	      term.write(curr_line)
			}
    } else if (ev.code == "KeyC" && ev.ctrlKey == true) {
      if (term.hasSelection()) {
      paste = term.getSelection();
      }
    } else if (ev.code == "KeyV" && ev.ctrlKey == true) {
      if (paste) {
		curr_line += paste;
    term.write(paste)
      }
		} else if (printable) {
		curr_line += ev.key;
		term.write(ev.key);
    }
		});

//added sometime between 4.5.0 and 4.12
// paste value
term.onPaste((data) => {
  console.log(data);
		curr_line += data;
		term.write(data);
		});
