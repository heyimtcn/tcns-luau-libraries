# TCN Libraries
Libraries written by me for Roblox.\
Rojo bindings are automatically generated with scripts\
The `model.rbxm` file contains every library (including `Communicator` which is multi-modular and experimental) with their dependencies already resolved.

# Descriptions
| Name            | Description                                                                                                                                                                                                                                                                             | Stable?                                   |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| Signal          | My own `Signal` implementation, similar to that of [RbxUtil](https://sleitnick.github.io/RbxUtil/api/Signal) but with more utility methods.                                                                                                                                             | yes                                       |
| Table           | A collection of utility functions for manipulating tables and arrays  (with functions from [RbxUtil](https://sleitnick.github.io/RbxUtil/api/TableUtil/) and the V programming language ([array](https://modules.vlang.io/#array), [map](https://modules.vlang.io/#map))).              | yes                                       |
| String          | A collection of utility functions for string manipulation (with functions from [the V programming language](https://modules.vlang.io/#string)).                                                                                                                                         | yes                                       |
| Locker          | Only lets one thread run between `:Lock()` and `:Unlock()` calls by queueing threads that call `:Lock()` whilst it's already locked. (attempts to simulate [this](https://en.wikipedia.org/wiki/Lock_(computer_science))).                                                              | yes                                       |
| Bufferizer      | Library that lets you turn most values into buffers, also includes helper functions for buffers. (i advise to NOT use this to store data in DataStores or any location which persists through sessions).                                                                                | yes                                       |
| ValueContainer  | `ValueContainer` store a value and emit `.Changed` signals when `.Value` changes (use `PropertyHandler` for table mutexes). comes with `Default`, `Computed`, `Animated` (eased, use `LerpUtils` for generating easing functions) and `Memo` (soon).                                    | yes                                       |
| LerpUtils       | Utility library for creating cubic beziers and lerping values (used by `ValueContainer` and `TweenPlus`) (TODO: easing directions for cubic beziers, if possible).                                                                                                                      | yes                                       |
| ModifierStack   | Simplifies managing stat modifiers (adding & subtracting base stats then multiplying and dividing by multiplyers). Allows for custom operators and operator order.                                                                                                                      | yes                                       |
| Mounter         | An extremely simple UI library inspired by [Blend](https://quenty.github.io/NevermoreEngine/api/Blend). (TODO: document).                                                                                                                                                               | yes                                       |
| Stream          | `Signal` that records appends through `:List()`. (TODO: add more utility?).                                                                                                                                                                                                             | yes                                       |
| Process         | Acts as a container for a system that can be killed and replaced (for stuff like handling cameras or AI) so systems don't overlap.                                                                                                                                                      | not tested enough                         |
| ReactiveTable   | Adds metamethods to tables that allow it to track changes (`.Changed`, `:GetChangedSignal(key)`) and allows you to extend objects with tracked data (`.extend(prototype)`,`.PropertyChanged`,`:GetPropertyChangedSignal(name)`).                                                        | recent changes that may cause instability |
| Tester          | Allows you to test libraries through `Stream`s using `.test()` and through Output using `.log()`.                                                                                                                                                                                       | yes                                       |
| TweenPlus       | Attempts to be a drop in replacement to `TweenService` with more features and control (tween multiple instances at once, custom easing functions, custom updater event, lets you set `Progress` directly, lets you play tweens in reverse).                                             | no                                        |
| Communicator    | Attempts to simplify server-client communication with `RemoteProperty`, `RemoteSignal`, `RemoteFunction` and uses `Bufferizer` under the hood to reduce packet size (TODO: support UnreliableRemoteEvent). Inspired by RbxUtil's [Comm](https://sleitnick.github.io/RbxUtil/api/Comm/). | no                                        |

> [!NOTE]
> "Stable?" comes from my experience and doesn't guarantee anything.

# Q&A
## Should i use these?
I suggest deciding that yourself, i can't guarantee these libraries will always work or fit in your project's scope, i just made these for myself and decided to put them on GitHub to make them easier to share with others.

## Will these be actively maintained?
Probably not. My interest for roblox is shrinking whilst I'm exploring Godot for more creative freedom. But if you wish, feel free to file an issue/PR.