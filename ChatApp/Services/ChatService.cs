namespace Service;
using System.Text.Json;
using System.Net.WebSockets;
using System.Text;


public class Message
{
    public string command { get; set; } = string.Empty; // 消息类型
    public string data { get; set; }= string.Empty;// 消息内容（动态解析）
}

public class ChatService
{
    private ClientWebSocket _webSocket= new ClientWebSocket();
    private string _userId=string.Empty;

    private Dictionary<string,List<string>> _msgMap = new Dictionary<string,List<string>>();

    public List<string> otherUsers = new List<string>();
    public ChatService()
    {
        // 随机生成一个唯一的用户 ID
        _userId = GenerateUserId();
    }
    public string GetUserId() => _userId;
    public List<string> GetHistoryMsgList(string userId)=> _msgMap.ContainsKey(userId)?_msgMap[userId]:new List<string>();

    public void SaveChatMessages(string userId,List<string> msgs) => _msgMap[userId] = new List<string>(msgs); // 存储副本，防止引用共享
    public void AddBackMessage(Message message) {
        // 检查用户是否已有消息列表
        if (!_msgMap.ContainsKey(message.command))
        {
            // 如果不存在，创建新列表并添加消息
            _msgMap[message.command] = new List<string>();
        }
        // 添加消息到用户的列表
        _msgMap[message.command].Add($"other User: {message.data}");
    }
    public async Task ConnectAsync(string uri)
    {
        var fullUri = $"{uri}?id={_userId}";
        await _webSocket.ConnectAsync(new Uri(fullUri), CancellationToken.None);
        Console.WriteLine($"WebSocket Connected, User ID is: {_userId}");
    }

    private string GenerateUserId()
    {
        // 生成一个随机的用户 ID，可以使用 GUID 或其他方法
        return Guid.NewGuid().ToString();
    }

    
    public async Task SendMessageAsync(string mes,string targetUser)
    {
        if (_webSocket == null || _webSocket.State != WebSocketState.Open)
        {
            throw new InvalidOperationException("WebSocket UnConnected");
        }
        Message message =  new Message(){
            command = targetUser??"server",
            data = mes
        };
        // 序列化 Message 对象为 JSON 字符串
        var json = JsonSerializer.Serialize(message);

        // 将 JSON 转为字节数组
        var buffer = Encoding.UTF8.GetBytes(json);

        // 发送数据
        await _webSocket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
    }

    public async Task<string> ReceiveMessageAsync()
    {
        if (_webSocket == null || _webSocket.State != WebSocketState.Open)
        {
            throw new InvalidOperationException("WebSocket UnConnected");
        }

        var buffer = new byte[1024];
        var result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
        return Encoding.UTF8.GetString(buffer, 0, result.Count);
    }

    public async Task DisconnectAsync()
    {
        if (_webSocket != null)
        {
            await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Cancel Connection", CancellationToken.None);
            _webSocket.Dispose();
        }
    }

    //监听是否有其他用户加入
    public async Task ListenAsync(Func<Message, Task> onMessageReceived)
    {
        try
        {
            var buffer = new byte[4096];

            while (_webSocket.State == WebSocketState.Open)
            {
                // 接收服务端消息
                var result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

                if (result.MessageType == WebSocketMessageType.Close)
                {
                    Console.WriteLine("WebSocket 连接已关闭");
                    break;
                }

                // 解析消息
                var jsonResponse = Encoding.UTF8.GetString(buffer, 0, result.Count);
                var message = JsonSerializer.Deserialize<Message>(jsonResponse);


                if (message != null)
                {
                    // 调用回调函数，更新用户列表
                    await onMessageReceived(message);
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"监听 WebSocket 消息时发生错误: {ex.Message}");
        }
    }
}