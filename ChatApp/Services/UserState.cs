namespace Service;
public class UserState
{
    public List<string> Users { get; private set; } = new();
    public List<string> hasMsgList = new List<string>();
    public event Action? OnChange;

    public void AddHasMsg(string id){
        hasMsgList.Add(id);
        NotifyStateChanged();
    }
    public void RemoveHasMsg(string id){
        hasMsgList.Remove(id);
        NotifyStateChanged();
    }
    public void UpdateUsers(List<string> users)
    {
        Users = users;
        NotifyStateChanged();
    }

    private void NotifyStateChanged() => OnChange?.Invoke();
}


