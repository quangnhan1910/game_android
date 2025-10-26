import 'package:flutter/material.dart';
import '../../models/friend_models.dart';
import '../../services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserSearchResult> _searchResults = [];
  List<FriendRequest> _pendingRequests = [];
  List<Friend> _friends = [];
  
  bool _isSearching = false;
  bool _isLoadingRequests = false;
  bool _isLoadingFriends = false;
  
  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    final result = await _friendService.getPendingRequests();
    if (result['success'] && mounted) {
      setState(() {
        _pendingRequests = result['data'] as List<FriendRequest>;
        _isLoadingRequests = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _pendingRequests = []; // Clear danh sách khi có lỗi
          _isLoadingRequests = false;
        });
      }
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);
    final result = await _friendService.getFriends();
    if (result['success'] && mounted) {
      setState(() {
        _friends = result['data'] as List<Friend>;
        _isLoadingFriends = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _friends = []; // Clear danh sách khi có lỗi
          _isLoadingFriends = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final result = await _friendService.searchUsers(query);
    if (result['success'] && mounted) {
      setState(() {
        _searchResults = result['data'] as List<UserSearchResult>;
        _isSearching = false;
      });
    } else {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFriendRequest(String username) async {
    final result = await _friendService.sendFriendRequest(username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _searchUsers(_searchController.text); // Refresh search
      }
    }
  }

  Future<void> _acceptRequest(int id) async {
    final result = await _friendService.acceptFriendRequest(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _loadPendingRequests();
        _loadFriends();
      }
    }
  }

  Future<void> _rejectRequest(int id) async {
    final result = await _friendService.rejectFriendRequest(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _loadPendingRequests();
      }
    }
  }

  Future<void> _unfriend(String username) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn hủy kết bạn với $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _friendService.unfriend(username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          _loadFriends();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bạn bè', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc tên người dùng',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),

          // Kết quả tìm kiếm
          if (_searchController.text.isNotEmpty)
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy người dùng',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return _buildUserTile(user);
                          },
                        ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // Các yêu cầu kết bạn - chỉ hiển thị khi có yêu cầu và không đang loading
                  if (_pendingRequests.isNotEmpty && !_isLoadingRequests) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Các yêu cầu kết bạn',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingRequests.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Danh sách yêu cầu kết bạn
                    ...(_pendingRequests.map((request) => _buildRequestTile(request)).toList()),

                    Divider(color: Colors.grey[300], thickness: 1, height: 20),
                  ],

                  // Bạn bè
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Bạn bè',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_friends.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${_friends.length}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Danh sách bạn bè
                  if (_isLoadingFriends)
                    const Center(child: CircularProgressIndicator())
                  else if (_friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Chưa có bạn bè',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ...(_friends.map((friend) => _buildFriendTile(friend))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserSearchResult user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: user.initials != null
              ? Text(
                  user.initials!,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                )
              : const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          user.username,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        trailing: user.friendshipStatus == 'friend'
            ? const Icon(Icons.check, color: Colors.blue)
            : user.friendshipStatus == 'pending'
                ? const Text('Đang chờ', style: TextStyle(color: Colors.orange))
                : IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    onPressed: () => _sendFriendRequest(user.username),
                  ),
      ),
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: request.senderInitials != null
              ? Text(
                  request.senderInitials!,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                )
              : const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          request.senderUsername,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _rejectRequest(request.id),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _acceptRequest(request.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(Friend friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: friend.initials != null
              ? Text(
                  friend.initials!,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                )
              : const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          friend.username,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_horiz, color: Colors.black87),
          color: Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _unfriend(friend.username),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

