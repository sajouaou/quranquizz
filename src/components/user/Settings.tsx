import React from 'react';



interface SettingsProps {
  settingsParameters: any[];
}

const Settings: React.FC<SettingsProps> = ({
  settingsParameters
}) => {
  return (
    <div className="settings-container">
    
    {settingsParameters.map((element,i) => (
      <React.Fragment key={i}>
      { i > 0 && (element.condition || element.condition == null) && element.notNext == null && <br key={`br${i}`} />}

      { element.type === "CHECKBOX" && (
      <>
      <label htmlFor={`switch${i}`}  key ={`switchLab${i}`}>{element.label}</label>
      <label className={`switch${i}`}  key ={`switch${i}`}>
        <input type="checkbox" checked={element.value} onChange={() => element.set(!element.value)} />
        <span className="slider round"></span>
      </label>
      </>    
      )}
      { element.type === "SELECT" && element.condition && (
          <>
          <label htmlFor={`select${i}`}  key ={`selectLab${i}`}>{element.label}</label>
          
          <select id={`select${i}`}  key ={`select${i}`} value={element.value} onChange={element.set}>
            { element.data.map((x:any) => (
                    <option key={x.id} value={x.value}>
                      {x.label} 
                    </option>
                  ))
            } 

          </select>
          </>
      )
      }
      {element.type === "BUTTON" && element.condition && (
        <button className={element.class}  onClick={element.click}  key ={`btn${i}`}>{element.label}</button>
      )
      }
      {element.type === "SLIDER" && (
      <>
        <label htmlFor={`slider${i}`}  key ={`sliderLab${i}`}>{element.label}</label>
        <input
          type="range"
          id={`slider${i}`}
          min={element.min}
          max={element.max}
          step={element.step}
          value={element.value}
          onChange={element.set}
          key ={`slider${i}`}
        />
      </>
      )}
      </React.Fragment>    
      ))
    }
    </div>
  );
};

export default Settings;