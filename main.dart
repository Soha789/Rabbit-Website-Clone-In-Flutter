import 'package:flutter/material.dart';

void main() {
  runApp(const TaskHiveApp());
}

// ------------------ MODELS ------------------

class AppUser {
  final String id;
  final String name;
  double rating;
  int ratingCount;

  AppUser({
    required this.id,
    required this.name,
    this.rating = 0,
    this.ratingCount = 0,
  });
}

class Bid {
  final String id;
  final String bidderId;
  final double price;
  final String message;

  Bid({
    required this.id,
    required this.bidderId,
    required this.price,
    required this.message,
  });
}

class ChatMessage {
  final String id;
  final String userId;
  final String text;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.time,
  });
}

class Task {
  final String id;
  String title;
  String description;
  double budget;
  String status; // open, assigned, completed
  final String ownerId;
  String? assignedTo; // userId
  final List<Bid> bids;
  final List<ChatMessage> messages;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.status,
    required this.ownerId,
    this.assignedTo,
    List<Bid>? bids,
    List<ChatMessage>? messages,
  })  : bids = bids ?? [],
        messages = messages ?? [];
}

// ------------------ ROOT APP ------------------

class TaskHiveApp extends StatefulWidget {
  const TaskHiveApp({super.key});

  @override
  State<TaskHiveApp> createState() => _TaskHiveAppState();
}

class _TaskHiveAppState extends State<TaskHiveApp> {
  // Fake users
  final List<AppUser> _users = [
    AppUser(id: 'u1', name: 'Alice (Client)'),
    AppUser(id: 'u2', name: 'Bob (Provider)'),
  ];

  AppUser? _currentUser;
  final List<Task> _tasks = [];
  int _taskCounter = 1;
  int _bidCounter = 1;
  int _msgCounter = 1;

  void _switchUser(AppUser u) {
    setState(() {
      _currentUser = u;
    });
  }

  void _createTask(String title, String desc, double budget) {
    if (_currentUser == null) return;
    final task = Task(
      id: 't${_taskCounter++}',
      title: title,
      description: desc,
      budget: budget,
      status: 'open',
      ownerId: _currentUser!.id,
    );
    setState(() {
      _tasks.add(task);
    });
  }

  void _placeBid(String taskId, double price, String message) {
    if (_currentUser == null) return;
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final bid = Bid(
      id: 'b${_bidCounter++}',
      bidderId: _currentUser!.id,
      price: price,
      message: message,
    );
    setState(() {
      task.bids.add(bid);
    });
  }

  void _acceptBid(String taskId, Bid bid) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    setState(() {
      task.assignedTo = bid.bidderId;
      task.status = 'assigned';
    });
  }

  void _completeTaskAndRate(String taskId, double rating, String comment) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final provider =
        _users.firstWhere((u) => u.id == (task.assignedTo ?? 'NONE'));
    setState(() {
      task.status = 'completed';
      // update provider rating (simple average)
      provider.rating = ((provider.rating * provider.ratingCount) + rating) /
          (provider.ratingCount + 1);
      provider.ratingCount += 1;

      // store rating as chat message note (optional)
      task.messages.add(ChatMessage(
        id: 'm${_msgCounter++}',
        userId: task.ownerId,
        text: 'Rating given: ${rating.toStringAsFixed(1)} ★\n$comment',
        time: DateTime.now(),
      ));
    });
  }

  void _sendMessage(String taskId, String text) {
    if (_currentUser == null) return;
    final task = _tasks.firstWhere((t) => t.id == taskId);
    setState(() {
      task.messages.add(ChatMessage(
        id: 'm${_msgCounter++}',
        userId: _currentUser!.id,
        text: text,
        time: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskHive Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: _currentUser == null
          ? UserSelectScreen(
              users: _users,
              onSelect: _switchUser,
            )
          : HomeScreen(
              currentUser: _currentUser!,
              users: _users,
              tasks: _tasks,
              onSwitchUser: _switchUser,
              onCreateTask: _createTask,
              onPlaceBid: _placeBid,
              onAcceptBid: _acceptBid,
              onCompleteTaskAndRate: _completeTaskAndRate,
              onSendMessage: _sendMessage,
            ),
    );
  }
}

// ------------------ USER SELECT (FAKE LOGIN) ------------------

class UserSelectScreen extends StatelessWidget {
  final List<AppUser> users;
  final void Function(AppUser) onSelect;

  const UserSelectScreen({
    super.key,
    required this.users,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return ListTile(
            title: Text(u.name),
            subtitle: Text(
                'Rating: ${u.rating.toStringAsFixed(1)} (${u.ratingCount})'),
            onTap: () => onSelect(u),
          );
        },
      ),
    );
  }
}

// ------------------ HOME SCREEN (with DefaultTabController) ------------------

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;
  final List<AppUser> users;
  final List<Task> tasks;
  final void Function(AppUser) onSwitchUser;
  final void Function(String title, String desc, double budget) onCreateTask;
  final void Function(String taskId, double price, String message) onPlaceBid;
  final void Function(String taskId, Bid bid) onAcceptBid;
  final void Function(String taskId, double rating, String comment)
      onCompleteTaskAndRate;
  final void Function(String taskId, String text) onSendMessage;

  const HomeScreen({
    super.key,
    required this.currentUser,
    required this.users,
    required this.tasks,
    required this.onSwitchUser,
    required this.onCreateTask,
    required this.onPlaceBid,
    required this.onAcceptBid,
    required this.onCompleteTaskAndRate,
    required this.onSendMessage,
  });

  AppUser _userById(String id) => users.firstWhere((u) => u.id == id,
      orElse: () => AppUser(id: 'x', name: 'Unknown'));

  @override
  Widget build(BuildContext context) {
    final me = currentUser;
    final myTasks = tasks.where((t) => t.ownerId == me.id).toList();
    final browseTasks = tasks.where((t) => t.ownerId != me.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('TaskHive - ${me.name}'),
          actions: [
            PopupMenuButton<AppUser>(
              onSelected: onSwitchUser,
              itemBuilder: (_) => users
                  .map((u) => PopupMenuItem(
                        value: u,
                        child: Text(u.name),
                      ))
                  .toList(),
              icon: const Icon(Icons.person),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Tasks'),
              Tab(text: 'Browse Tasks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // My tasks
            myTasks.isEmpty
                ? const Center(child: Text('No tasks created yet.'))
                : ListView.builder(
                    itemCount: myTasks.length,
                    itemBuilder: (_, i) {
                      final t = myTasks[i];
                      return TaskCard(
                        task: t,
                        me: me,
                        owner: _userById(t.ownerId),
                        provider: t.assignedTo != null
                            ? _userById(t.assignedTo!)
                            : null,
                        onTap: () => _openTaskDetail(context, t),
                      );
                    },
                  ),
            // Browse tasks
            browseTasks.isEmpty
                ? const Center(child: Text('No tasks to browse.'))
                : ListView.builder(
                    itemCount: browseTasks.length,
                    itemBuilder: (_, i) {
                      final t = browseTasks[i];
                      return TaskCard(
                        task: t,
                        me: me,
                        owner: _userById(t.ownerId),
                        provider: t.assignedTo != null
                            ? _userById(t.assignedTo!)
                            : null,
                        onTap: () => _openTaskDetail(context, t),
                      );
                    },
                  ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateTaskDialog(context),
          label: const Text('Post Task'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Task'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: budgetCtrl,
                decoration: const InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              final budget = double.tryParse(budgetCtrl.text) ?? 0;
              if (title.isEmpty) return;
              onCreateTask(title, desc, budget);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          me: currentUser,
          users: users,
          onPlaceBid: onPlaceBid,
          onAcceptBid: onAcceptBid,
          onCompleteTaskAndRate: onCompleteTaskAndRate,
          onSendMessage: onSendMessage,
        ),
      ),
    );
  }
}

// ------------------ TASK CARD ------------------

class TaskCard extends StatelessWidget {
  final Task task;
  final AppUser me;
  final AppUser owner;
  final AppUser? provider;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.me,
    required this.owner,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'open': Colors.green,
      'assigned': Colors.orange,
      'completed': Colors.blueGrey,
    }[task.status]!;
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        onTap: onTap,
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 4),
            Text('Budget: ${task.budget.toStringAsFixed(0)}'),
            Text('Owner: ${owner.name}'),
            if (provider != null) Text('Provider: ${provider!.name}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              task.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text('${task.bids.length} bids'),
          ],
        ),
      ),
    );
  }
}

// ------------------ TASK DETAIL SCREEN ------------------

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final AppUser me;
  final List<AppUser> users;
  final void Function(String taskId, double price, String message) onPlaceBid;
  final void Function(String taskId, Bid bid) onAcceptBid;
  final void Function(String taskId, double rating, String comment)
      onCompleteTaskAndRate;
  final void Function(String taskId, String text) onSendMessage;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.me,
    required this.users,
    required this.onPlaceBid,
    required this.onAcceptBid,
    required this.onCompleteTaskAndRate,
    required this.onSendMessage,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  AppUser _userById(String id) => widget.users.firstWhere((u) => u.id == id,
      orElse: () => AppUser(id: 'x', name: 'Unknown'));

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final me = widget.me;
    final isOwner = task.ownerId == me.id;
    final provider =
        task.assignedTo != null ? _userById(task.assignedTo!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(task.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description),
                const SizedBox(height: 4),
                Text('Budget: ${task.budget.toStringAsFixed(0)}'),
                Text('Status: ${task.status}'),
                Text('Owner: ${_userById(task.ownerId).name}'),
                if (provider != null) Text('Provider: ${provider.name}'),
              ],
            ),
          ),
          const Divider(),
          if (!isOwner && task.status == 'open')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.gavel),
                label: const Text('Place Bid'),
                onPressed: () => _showBidDialog(context),
              ),
            ),
          if (isOwner && task.status == 'open')
            Expanded(
              child: _buildBidList(context, isOwner),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (isOwner &&
                      task.status == 'assigned' &&
                      task.assignedTo != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Completed & Rate'),
                        onPressed: () => _showRatingDialog(context),
                      ),
                    ),
                  Expanded(child: _buildChatSection(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBidList(BuildContext context, bool isOwner) {
    final task = widget.task;
    if (task.bids.isEmpty) {
      return const Center(child: Text('No bids yet.'));
    }
    return ListView.builder(
      itemCount: task.bids.length,
      itemBuilder: (_, i) {
        final b = task.bids[i];
        final bidder = _userById(b.bidderId);
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Price: ${b.price.toStringAsFixed(0)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By: ${bidder.name}'),
                Text(b.message),
              ],
            ),
            trailing: isOwner
                ? ElevatedButton(
                    child: const Text('Accept'),
                    onPressed: () {
                      widget.onAcceptBid(task.id, b);
                      setState(() {});
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildChatSection(BuildContext context) {
    final task = widget.task;
    final me = widget.me;
    final msgCtrl = TextEditingController();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Chat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: task.messages.length,
            itemBuilder: (_, i) {
              final m = task.messages[i];
              final isMe = m.userId == me.id;
              final user = _userById(m.userId);
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.indigo : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        m.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: msgCtrl,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final text = msgCtrl.text.trim();
                if (text.isEmpty) return;
                widget.onSendMessage(widget.task.id, text);
                setState(() {});
                msgCtrl.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showBidDialog(BuildContext context) {
    final priceCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Place Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Your Price'),
            ),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0;
              widget.onPlaceBid(widget.task.id, price, msgCtrl.text.trim());
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rate Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rating (1 to 5)'),
            StatefulBuilder(
              builder: (context, setLocalState) {
                return Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: rating.toStringAsFixed(1),
                  value: rating,
                  onChanged: (v) {
                    setLocalState(() {
                      rating = v;
                    });
                  },
                );
              },
            ),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onCompleteTaskAndRate(
                widget.task.id,
                rating,
                commentCtrl.text.trim(),
              );
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
