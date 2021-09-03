# TODO system

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

# Zettel system

* Tags
* UIDs
* References (?)
* Pandoc / LaTeX
* `idea` alias / script
* Directory-agnostic: should be able to run in any project dir
* GNU Stow:
    * Maintain central Zettel repo but symlink to different project dirs

---

# Build / deployment system

* Auto-generate Makefiles from YAML / Markdown dependency lists
* Topological sorting: `tsort`
