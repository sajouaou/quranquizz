import React, { useState, useCallback, useEffect } from 'react';
import useWebSocket, { ReadyState } from 'react-use-websocket';
import { useSocketIO } from 'react-use-websocket';
import { SocketIOMessageData } from 'react-use-websocket/dist/lib/use-socket-io';

interface WebSocketDemoProps 
{
  endpoint: string;
  username: string;
  room: string;
}

export const WebSocketDemo: React.FC<WebSocketDemoProps> = ({endpoint,username,room}) => {
  //Public API that will echo messages sent to it back to the client
  const [socketUrl, setSocketUrl] = useState(endpoint);
  //const [messageHistory, setMessageHistory] = useState<SocketIOMessageData[]>([]);
  const [messageHistory, setMessageHistory] = useState<any[]>([]);

  const { sendJsonMessage, lastJsonMessage, readyState } = useWebSocket(socketUrl,{
    queryParams: { username,room },
    share: true,
  });
  

  useEffect(() => {
    setSocketUrl(endpoint);
    
  }, [endpoint]);

  const handleClickChangeSocketUrl = useCallback(
    () => setSocketUrl('wss://echo.websocket.org'),
    []
  );

  // Run when a new WebSocket message is received (lastJsonMessage)
  useEffect(() => {
    if (lastJsonMessage !== null) {
      console.log(`Got a new message: ${lastJsonMessage}`)
    }
  }, [lastJsonMessage])

  const handleClickSendMessage = useCallback(() => sendJsonMessage({msg:'Hello'}), []);

  const connectionStatus = {
    [ReadyState.CONNECTING]: 'Connecting',
    [ReadyState.OPEN]: 'Open',
    [ReadyState.CLOSING]: 'Closing',
    [ReadyState.CLOSED]: 'Closed',
    [ReadyState.UNINSTANTIATED]: 'Uninstantiated',
  }[readyState];

  return (
    <div>
      <button onClick={handleClickChangeSocketUrl}>
        Click Me to change Socket Url
      </button>
      <button
        onClick={handleClickSendMessage}
        //disabled={readyState !== ReadyState.OPEN}
      >
        Click Me to send 'Hello'
      </button>
      <span>The WebSocket is currently {connectionStatus}</span>
      {lastJsonMessage ? <span>Last message: {lastJsonMessage.data}</span> : null}
      <ul>
        {messageHistory.map((message, idx) => (
          <span key={idx}>{message ? message.data : null}</span>
        ))}
      </ul>
    </div>
  );
};