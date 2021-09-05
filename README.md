# Bash startup scripts (macbook)

## bashrc

The following is the content of ~/.bashrc:
```bash
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*.{sh,bash}; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc
```

## TODO system

* Tags
* Markdown
* "Terraced" architecture:
    * Support basic functionality with Bash; add more complex features in Python
* Topological sorting:
    * Use to construct agendas, schedules, and reminders
    * cf. PERT (Program Evaluation and Review Technique)
    * Critical Path Method (CPM)
* Hierarchical items:
    * Dependencies
    * Categories: Use ':' as token while parsing args

---

## Zettel system

* Tags
* UIDs
* References (?)
* Pandoc / LaTeX
* `idea` alias / script
* Directory-agnostic: should be able to run in any project dir
* GNU Stow:
    * Maintain central Zettel repo but symlink to different project dirs

---

## Build / deployment system

* Auto-generate Makefiles from YAML / Markdown dependency lists
* Topological sorting: `tsort`

---

## Queue

### Ideas
* Redis:
    * Use redis-cli to manage queue
* Name files after processes a la `bq`
* Daemonize a "listener"
    * Could also use FIFO, but this is not very robust

### Functions
* set
    * Set default queue
* cat
* grep
* sort
    * sortby
* rank
* join
* map
    * printf
* filter
* select
* append
    * (column)
* style
    * Set markup style, delimiter, etc.
    * qconfig
* include
    * Sets config options if included file is .conf or .yaml
* merge
* split
* edit
* next
* pop, push, peek
* remove
* defer
* transaction
    * revert
    * commit
    * schedule
    * `task`


q() { :; }
qconfig() { :; }
qmaybe() { :; }
qrate() { :; }
qdo() { :; }
qrun() { :; }
qmod() { :; }
qdef() { :; }
qinclude() { :; }
qreverse() { :; }
qpop() { :; }
qpush() { :; }
qswitch() { :; }
qfile() { :; }
qprintf() { :; }
qlog() { :; }
qmake() { :; }
qsort() { :; }
qput() { :; }
qadd() { :; }
qgroup() { :; }
qsplit() { :; }

qdump() { :; }
qgrep() { :; }
