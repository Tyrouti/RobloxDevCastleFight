# Castle Fight — working rules

Before every task, read this file and docs/MASTER_SPEC.md; also read docs/ARCHITECTURE.md for architectural changes.

- Current stage: foundation. Do not implement a match or expand the MVP without a task.
- Change approved balance only with explicit approval; update the specification and configurations together.
- Mark unresolved rules as TODO / not approved. Do not invent values.
- The server controls gold, construction, spawning, movement/combat, the sword, timer, and match outcome. The client sends intentions.
- Use ModuleScripts, --!strict, parameter/result types, and explicit dependencies without cycles. Keep balance numbers in src/shared/Config.
- Check real Roblox APIs against documentation and available tool schemas; do not invent methods.
- Do not delete or overwrite existing places/assets. Do not change Workspace through code synchronization.
- Before Studio actions, check studio_status and the target place. Do not publish without a task.
- Edit code sources on disk; do not maintain parallel code copies through MCP and Rojo.
- Meshy and any 3D generation require separate user permission. Do not spend credits or generate assets during the foundation stage.
- Monetization is cosmetic only. Do not add DataStores, lobbies, rankings, inventories, or other systems outside the MVP without a task.
- Do not commit secrets, tool binaries, build output, or Studio lock files. Do not commit/push without a task.
- At the end, list changed files, checks actually executed, verification limitations, and required manual actions. Do not describe a prepared synchronization configuration as an active connection.
