# Godot MCP

开源 Godot MCP 服务，让 AI 助手（Claude Code、Cursor、Codex 等）通过 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) 直接操控 Godot 4 编辑器。

```
AI 客户端  ←—stdio/MCP—→  Node.js 服务  ←—WebSocket:6505—→  Godot 编辑器插件
```

## 实现概览

| 组件 | 职责 |
|------|------|
| **Godot 插件** | WebSocket 客户端，接收 JSON-RPC 请求，调用编辑器 API 执行命令 |
| **Node.js MCP 服务** | stdio 与 AI 客户端通信，WebSocket 服务端（默认端口 6505）转发工具调用 |
| **命令路由** | `command_router.gd` 聚合 24 个 command 模块，共 **173** 个 handler |
| **运行时服务** | 3 个 autoload（`MCPRuntimeBridge` / `MCPInputBridge` / `MCPScreenshotBridge`），通过 `user://` IPC 支持游戏内检视、输入模拟与截图 |

### 核心特性

- **UndoRedo 集成**：节点增删改、属性变更等操作均走编辑器撤销栈
- **智能类型解析**：`Vector2(100, 200)`、`#ff0000`、`Color(1,0,0)` 等字符串自动转换
- **断线重连**：插件侧指数退避重连（1s → 60s）
- **心跳保活**：双向 ping/pong，保持 WebSocket 长连接
- **JSON-RPC 2.0**：Godot 插件与 Node.js 服务之间的标准协议

## 工具分类

**173 个 MCP 工具**，覆盖 **26 个类别**：

| 类别 | 工具数 | 代表能力 |
|------|--------|----------|
| Project | 7 | 项目信息、文件搜索、UID 转换、项目设置读写 |
| Scene | 10 | 场景树、创建/删除/实例化场景、运行/停止、@export 变量 |
| Node | 14 | 增删改移、属性读写、信号连接、分组、资源挂载 |
| Script | 8 | 脚本 CRUD、挂载、语法校验、全文搜索 |
| Editor | 13 | 编辑器/游戏截图、相机控制、错误日志、截图对比、自动关闭弹窗 |
| Input | 7 | 键鼠/动作模拟、输入映射配置（含 deadzone） |
| Runtime | 20 | 游戏内场景树、属性读写、信号监听、录制回放、UI 点击、导航 |
| Animation | 6 | 动画轨道、关键帧、AnimationPlayer CRUD |
| TileMap | 6 | 单元格读写、区域填充、已用格子查询 |
| Theme/UI | 7 | 主题创建、Control 布局、颜色/字体/StyleBox 覆盖 |
| Profiling | 2 | FPS、内存、Draw Call、物理等性能监视器 |
| Batch/Refactor | 9 | 批量添加节点、按类型批量改属性、跨场景更新、依赖/循环检测 |
| Shader | 6 | 着色器 CRUD、材质分配、参数读写 |
| Export | 3 | 导出预设列表、导出命令生成 |
| Resource | 6 | `.tres` 读写、Autoload 注册/移除 |
| Physics | 6 | 碰撞体配置、物理层（含 layer 名称解析）、RayCast |
| 3D Scene | 6 | 网格实例、相机、灯光、环境、GridMap |
| Particle | 5 | GPU 粒子创建、材质、渐变、预设（火焰/烟雾/火花） |
| Navigation | 6 | 导航区域/代理、网格烘焙、路径计算 |
| Audio | 6 | 音频播放器、总线、效果器 |
| AnimationTree | 8 | 状态机、过渡、混合树、参数设置 |
| Analysis | 4 | 场景复杂度、信号流、未使用资源、项目统计 |
| Testing/QA | 5 | 测试场景、断言、压力测试 |
| Android | 4 | adb 设备列表、APK 导出部署、预设详情 |

<details>
<summary>展开查看全部 173 个工具名称</summary>

**Project:** `get_project_info` · `get_filesystem_tree` · `search_files` · `get_project_settings` · `set_project_setting` · `uid_to_project_path` · `project_path_to_uid`

**Scene:** `get_scene_tree` · `get_scene_file_content` · `create_scene` · `open_scene` · `delete_scene` · `add_scene_instance` · `play_scene` · `stop_scene` · `save_scene` · `get_scene_exports`

**Node:** `add_node` · `delete_node` · `duplicate_node` · `move_node` · `update_property` · `get_node_properties` · `add_resource` · `set_anchor_preset` · `rename_node` · `connect_signal` · `disconnect_signal` · `get_node_groups` · `set_node_groups` · `find_nodes_in_group`

**Script:** `list_scripts` · `read_script` · `create_script` · `edit_script` · `attach_script` · `get_open_scripts` · `validate_script` · `search_in_files`

**Editor:** `get_editor_errors` · `get_editor_screenshot` · `get_game_screenshot` · `execute_editor_script` · `clear_output` · `get_signals` · `reload_plugin` · `reload_project` · `get_output_log` · `get_editor_camera` · `set_editor_camera` · `set_auto_dismiss` · `compare_screenshots`

**Input:** `simulate_key` · `simulate_mouse_click` · `simulate_mouse_move` · `simulate_action` · `simulate_sequence` · `get_input_actions` · `set_input_action`

**Runtime:** `get_game_scene_tree` · `get_game_node_properties` · `set_game_node_property` · `execute_game_script` · `capture_frames` · `monitor_properties` · `start_recording` · `stop_recording` · `replay_recording` · `find_nodes_by_script` · `get_autoload` · `batch_get_properties` · `find_ui_elements` · `click_button_by_text` · `wait_for_node` · `find_nearby_nodes` · `navigate_to` · `move_to` · `watch_signals`

**Animation:** `list_animations` · `create_animation` · `add_animation_track` · `set_animation_keyframe` · `get_animation_info` · `remove_animation`

**TileMap:** `tilemap_set_cell` · `tilemap_fill_rect` · `tilemap_get_cell` · `tilemap_clear` · `tilemap_get_info` · `tilemap_get_used_cells`

**Theme/UI:** `create_theme` · `set_theme_color` · `set_theme_constant` · `set_theme_font_size` · `set_theme_stylebox` · `get_theme_info` · `setup_control`

**Profiling:** `get_performance_monitors` · `get_editor_performance`

**Batch/Refactor:** `find_nodes_by_type` · `find_signal_connections` · `batch_set_property` · `find_node_references` · `get_scene_dependencies` · `cross_scene_set_property` · `find_script_references` · `detect_circular_dependencies` · `batch_add_nodes`

**Shader:** `create_shader` · `read_shader` · `edit_shader` · `assign_shader_material` · `set_shader_param` · `get_shader_params`

**Export:** `list_export_presets` · `export_project` · `get_export_info`

**Resource:** `read_resource` · `edit_resource` · `create_resource` · `get_resource_preview` · `add_autoload` · `remove_autoload`

**Physics:** `setup_physics_body` · `setup_collision` · `set_physics_layers` · `get_physics_layers` · `get_collision_info` · `add_raycast`

**3D Scene:** `add_mesh_instance` · `setup_camera_3d` · `setup_lighting` · `setup_environment` · `add_gridmap` · `set_material_3d`

**Particle:** `create_particles` · `set_particle_material` · `set_particle_color_gradient` · `apply_particle_preset` · `get_particle_info`

**Navigation:** `setup_navigation_region` · `setup_navigation_agent` · `bake_navigation_mesh` · `set_navigation_layers` · `get_navigation_info` · `get_navigation_path`

**Audio:** `add_audio_player` · `add_audio_bus` · `add_audio_bus_effect` · `set_audio_bus` · `get_audio_bus_layout` · `get_audio_info`

**AnimationTree:** `create_animation_tree` · `get_animation_tree_structure` · `set_tree_parameter` · `add_state_machine_state` · `remove_state_machine_state` · `add_state_machine_transition` · `remove_state_machine_transition` · `set_blend_tree_node`

**Analysis:** `analyze_scene_complexity` · `analyze_signal_flow` · `find_unused_resources` · `get_project_statistics`

**Testing/QA:** `run_test_scenario` · `assert_node_state` · `assert_screen_text` · `run_stress_test` · `get_test_report`

**Android:** `list_android_devices` · `deploy_to_android` · `get_android_build_info` · `get_android_preset_info`

</details>

## 项目结构

```
godot-mcp/
├── addons/godot_mcp/              # Godot 编辑器插件（复制到你的项目）
│   ├── plugin.gd                  # 插件入口，注入 autoload
│   ├── plugin.cfg
│   ├── websocket_client.gd        # WebSocket 客户端 + JSON-RPC 分发
│   ├── command_router.gd          # 命令路由，注册全部 handler
│   ├── commands/                  # 24 个命令模块（173 个工具实现）
│   │   ├── base_commands.gd       # 基类：Undo、运行时 IPC、截图等
│   │   ├── project_commands.gd
│   │   ├── scene_commands.gd
│   │   ├── node_commands.gd
│   │   ├── script_commands.gd
│   │   ├── editor_commands.gd
│   │   ├── input_commands.gd
│   │   ├── runtime_commands.gd
│   │   ├── animation_commands.gd
│   │   ├── tilemap_commands.gd
│   │   ├── theme_commands.gd
│   │   ├── profiling_commands.gd
│   │   ├── batch_commands.gd
│   │   ├── shader_commands.gd
│   │   ├── export_commands.gd
│   │   ├── resource_commands.gd
│   │   ├── physics_commands.gd
│   │   ├── scene_3d_commands.gd
│   │   ├── particle_commands.gd
│   │   ├── navigation_commands.gd
│   │   ├── audio_commands.gd
│   │   ├── animation_tree_commands.gd
│   │   ├── analysis_commands.gd
│   │   ├── test_commands.gd
│   │   └── android_commands.gd
│   ├── services/                  # 运行时 autoload 服务
│   │   ├── mcp_runtime_bridge.gd  # 游戏内场景树 / 属性 / 脚本执行
│   │   ├── mcp_input_bridge.gd    # 输入事件队列
│   │   └── mcp_screenshot_bridge.gd
│   └── utils/
│       ├── type_parser.gd         # Vector2 / Color 等类型解析
│       ├── node_utils.gd
│       └── resource_utils.gd
├── server/                        # Node.js MCP 服务
│   ├── src/
│   │   ├── index.ts               # MCP stdio 入口
│   │   ├── godot-bridge.ts        # WebSocket 服务端 + JSON-RPC
│   │   ├── tools.ts               # 工具注册逻辑
│   │   └── tool-manifest.ts       # 173 个工具定义（名称 / 描述 / 参数）
│   └── build/index.js             # 构建产物（MCP 启动入口）
├── example/                       # 演示 Godot 项目
├── .mcp.json.example              # MCP 客户端配置示例
└── README.md
```

## 环境要求

- **Godot** 4.4+
- **Node.js** 18+
- 任意支持 MCP 的客户端：Claude Code、Cursor、Codex CLI、Cline、Windsurf 等

## 使用方式

### 1. 安装 Godot 插件

将 `addons/godot_mcp/` 复制到你的 Godot 项目的 `addons/` 目录：

```bash
cp -r addons/godot_mcp /path/to/your-game/addons/
```

在 Godot 中启用：**项目 → 项目设置 → 插件 → Godot MCP → 启用**

> 插件启用时会自动注入 3 个 autoload（`MCPRuntimeBridge` 等），停用插件后会自动移除。

### 2. 构建 MCP 服务

```bash
cd server
npm install
npm run build
```

构建完成后入口为 `server/build/index.js`。

### 3. 配置 AI 客户端

将以下配置加入 MCP 配置文件（**请把路径改成你的实际路径**）：

| 客户端 | 配置文件位置 |
|--------|-------------|
| Claude Code | 项目根目录 `.mcp.json` |
| Cursor | Settings → MCP，或 `~/.cursor/mcp.json` |
| Codex CLI | `~/.codex/config.toml` 中的 MCP 段 |
| Cline / Roo Code | 对应扩展的 MCP 设置 |

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["D:/godot-mcp/server/build/index.js"],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    }
  }
}
```

也可直接参考仓库内的 [`.mcp.json.example`](.mcp.json.example)。

### 4. 开始使用

1. **先**用 Godot 打开你的项目（确保插件已启用）
2. 启动 AI 客户端，确认 MCP 服务 `godot-mcp` 已连接
3. 在对话中让 AI 操作编辑器，例如：
   - 「获取当前场景树」
   - 「在根节点下添加 CharacterBody2D，命名为 Player」
   - 「创建 GDScript 并挂载到 Player」
   - 「运行当前场景，然后截取游戏画面」
   - 「给 TileMap 填充一片草地」

### 5. 示例项目

仓库内 `example/` 目录包含可运行的演示项目：

```bash
godot --editor example/project.godot
```

## 工作原理

1. AI 客户端通过 **stdio** 调用 MCP 工具（如 `add_node`）
2. Node.js 服务将请求转为 **JSON-RPC**，经 **WebSocket** 发往 Godot 插件
3. Godot 插件的 `command_router` 分发到对应 handler，调用 **EditorInterface** 等 API 执行
4. 结果沿原路返回给 AI 客户端

**运行时工具**（如 `get_game_scene_tree`）额外依赖：

- 编辑器处于 **播放** 状态
- `MCPRuntimeBridge` autoload 在游戏进程中轮询 `user://mcp_runtime_req.json` 并写回响应

## 扩展工具

新增一个 MCP 工具需要三步：

1. 在 `addons/godot_mcp/commands/` 新建或修改命令类，在 `get_commands()` 中注册 handler
2. 在 `command_router.gd` 的 `COMMAND_MODULES` 数组中添加该脚本路径
3. 在 `server/src/tool-manifest.ts` 的 `TOOL_DEFINITIONS` 中添加工具名称、描述和参数 schema

然后重新构建服务：

```bash
cd server && npm run build
```

## 已知限制

- **Android 工具**：`list_android_devices` 通过 `adb devices` 列出设备；`deploy_to_android` 调用 Godot 无头导出并通过 adb 安装（需配置 Android 导出预设且 adb 在 PATH 中）
- **运行时工具**：需先 `play_scene`，且游戏进程需加载 `MCPRuntimeBridge` autoload；`watch_signals` 在游戏运行期间监听指定节点的信号发射
- **跨场景批量修改**（`cross_scene_set_property`）：在内存中修改场景实例，需手动保存对应场景文件
- 部分编辑器 API 在不同 Godot 小版本间可能有差异，建议在 **4.4+** 上使用

## License

MIT
