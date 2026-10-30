
import { useEffect, useState } from "react";
import "./App.css";

const modules = [
  { name: "Agriculture", icon: "🌾", description: "Crops, weather, soil, irrigation and farm operations.", status: "In development" },
  { name: "Smart Territory", icon: "◎", description: "Countries, provinces, districts, cities and villages.", status: "Database foundation" },
  { name: "Energy / MU", icon: "ϟ", description: "Meter readings, consumption, demand and outages.", status: "Planned" },
  { name: "Industrial IoT", icon: "▦", description: "Machinery, PLCs, sensors and production telemetry.", status: "Planned" },
  { name: "Cameras", icon: "◉", description: "Production cameras and visual inspection events.", status: "Planned" },
  { name: "Data Lab", icon: "⌬", description: "Explore, validate and analyse operational data.", status: "In development" },
];

const navigation = ["Overview", ...modules.map((item) => item.name)];

export default function App() {
  const [active, setActive] = useState("Overview");
  const [scope, setScope] = useState("South Africa");

  
const [latitude, setLatitude] = useState("-29.0852");
const [longitude, setLongitude] = useState("26.1596");
const [startDate, setStartDate] = useState("2026-10-01");
const [endDate, setEndDate] = useState("2026-10-07");
const [threshold, setThreshold] = useState("30");

const [analysisParams, setAnalysisParams] = useState({
  latitude: "-29.0852",
  longitude: "26.1596",
  start_date: "2026-10-01",
  end_date: "2026-10-07",
  threshold_c: "30",
});

  
  const [agricultureData, setAgricultureData] = useState(null);
  const [agricultureLoading, setAgricultureLoading] = useState(false);
  const [agricultureError, setAgricultureError] = useState("");

  
useEffect(() => {
  if (active !== "Agriculture") return;

  const controller = new AbortController();

  async function loadAgricultureData() {
    setAgricultureLoading(true);
    setAgricultureError("");

    try {
      const params = new URLSearchParams(analysisParams);

      const response = await fetch(
        `/api/agriculture/maize-heat?${params}`,
        { signal: controller.signal }
      );

      if (!response.ok) {
        throw new Error(`API request failed: HTTP ${response.status}`);
      }

      const data = await response.json();
      setAgricultureData(data);
    } catch (error) {
      if (error.name !== "AbortError") {
        setAgricultureError(error.message);
      }
    } finally {
      if (!controller.signal.aborted) {
        setAgricultureLoading(false);
      }
    }
  }

  loadAgricultureData();

  return () => controller.abort();
}, [active, analysisParams]);


  

  

  const activeModule = modules.find((item) => item.name === active);

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-logo">K</div>
          <div>
            <strong>KEULDER</strong>
            <small>INTELLIGENCE PLATFORM</small>
          </div>
        </div>

        <div className="nav-label">WORKSPACE</div>
        <nav className="navigation">
          {navigation.map((item) => (
            <button
              key={item}
              className={active === item ? "nav-item active" : "nav-item"}
              onClick={() => setActive(item)}
            >
              <span className="nav-icon">
                {item === "Overview" ? "◈" : modules.find((m) => m.name === item)?.icon}
              </span>
              {item}
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <span className="status-dot" />
          <div>
            <strong>Local development</strong>
            <small>Demo data · Not production</small>
          </div>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="breadcrumb">Keulder <span>/</span> {active}</div>
          <div className="topbar-right">
            <span className="environment"><span className="status-dot" /> LOCAL</span>
            <button className="settings-button" onClick={() => alert("Settings will be added in a later step.")}>
              ⚙ Settings
            </button>
          </div>
        </header>

        <div className="page-content">
          <section className="page-heading">
            <div>
              <div className="eyebrow">OPERATIONS INTELLIGENCE</div>
              <h1>{activeModule ? activeModule.name : "National Operations Overview"}</h1>
              <p>
                {activeModule
                  ? activeModule.description
                  : "One platform for territory, agriculture, energy and industrial data."}
              </p>
            </div>
            <label className="scope-control">
              <span>Viewing scope</span>
              <select value={scope} onChange={(event) => setScope(event.target.value)}>
                <option>South Africa</option>
                <option>Free State</option>
                <option>Bloemfontein</option>
                <option>Demo Facility</option>
              </select>
            </label>
          </section>

          {active === "Overview" ? (
            <>
              <div className="demo-notice">
                <span>ⓘ</span>
                <div>
                  <strong>Demonstration dashboard</strong>
                  <p>Illustrative figures below are not live measurements. We will replace them with verified API data.</p>
                </div>
              </div>

              <section className="metrics-grid">
                {[
                  ["Connected assets", "—", "Awaiting data integration"],
                  ["Live data streams", "—", "Awaiting data integration"],
                  ["Open alerts", "—", "No alert feed connected"],
                  ["Data quality", "—", "Not yet calculated"],
                ].map(([label, value, note]) => (
                  <article className="metric-card" key={label}>
                    <div className="metric-top">
                      <span>{label}</span>
                      <span className="metric-symbol">↗</span>
                    </div>
                    <div className="metric-value">{value}</div>
                    <div className="metric-note">{note}</div>
                  </article>
                ))}
              </section>

              <section className="overview-grid">
                <article className="panel data-panel">
                  <div className="panel-heading">
                    <div>
                      <h2>Platform data flow</h2>
                      <p>System integration status</p>
                    </div>
                    <span className="tag">VERSION 1</span>
                  </div>
                  <div className="data-flow">
                    <div className="flow-node">
                      <span>01</span>
                      <strong>Data sources</strong>
                      <small>Sensors · Weather · Records</small>
                    </div>
                    <div className="flow-connector">→</div>
                    <div className="flow-node">
                      <span>02</span>
                      <strong>FastAPI</strong>
                      <small>Validation · Processing</small>
                    </div>
                    <div className="flow-connector">→</div>
                    <div className="flow-node">
                      <span>03</span>
                      <strong>PostgreSQL</strong>
                      <small>Schemas · Spatial data</small>
                    </div>
                  </div>
                  <div className="panel-footnote">
                    The foundation is being built locally before production deployment.
                  </div>
                </article>

                <article className="panel status-panel">
                  <div className="panel-heading">
                    <div>
                      <h2>Development status</h2>
                      <p>Current platform foundation</p>
                    </div>
                  </div>
                  {[
                    ["PostgreSQL database", "Configured"],
                    ["FastAPI backend", "Available locally"],
                    ["React dashboard", "Running locally"],
                    ["Google Cloud hosting", "Not deployed"],
                  ].map(([label, value]) => (
                    <div className="status-row" key={label}>
                      <span className="status-dot" />
                      <span>{label}</span>
                      <small>{value}</small>
                    </div>
                  ))}
                </article>
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Platform modules</h2>
                    <p>Choose a domain to explore its workspace.</p>
                  </div>
                </div>
                <div className="modules-grid">
                  {modules.map((item) => (
                    <button className="module-card" key={item.name} onClick={() => setActive(item.name)}>
                      <div className="module-top">
                        <span className="module-icon">{item.icon}</span>
                        <span className="module-arrow">↗</span>
                      </div>
                      <h3>{item.name}</h3>
                      <p>{item.description}</p>
                      <div className="module-status">{item.status}</div>
                    </button>
                  ))}
                </div>
              </section>
            </>
          ) : (
            <section className="panel module-workspace">
              <div className="module-workspace-icon">{activeModule?.icon}</div>
              <div className="eyebrow">MODULE WORKSPACE</div>
              <h2>{activeModule?.name}</h2>
              <p>{activeModule?.description}</p>
              <div className="workspace-info">
                <strong>Current stage</strong>
                <span>{activeModule?.status}</span>
              </div>

              
  {active === "Agriculture" && (
    <div className="agriculture-results">

    
    
      <div className="agriculture-controls">
        <div className="agriculture-controls-heading">
          <h3>Analysis parameters</h3>
          <p>Choose the location, period and heat threshold for your analysis.</p>
        </div>

        <form
          className="agriculture-form"
          onSubmit={(event) => {
            event.preventDefault();

            const lat = Number(latitude);
            const lon = Number(longitude);
            const limit = Number(threshold);

            if (
              latitude.trim() === "" ||
              longitude.trim() === "" ||
              threshold.trim() === "" ||
              !Number.isFinite(lat) ||
              !Number.isFinite(lon) ||
              lat < -90 || lat > 90 ||
              lon < -180 || lon > 180 ||
              !Number.isFinite(limit) ||
              limit < -50 || limit > 70
            ) {
              setAgricultureError(
                "Enter valid coordinates and a threshold between -50°C and 70°C."
              );
              return;
            }

            if (!startDate || !endDate || startDate > endDate) {
              setAgricultureError(
                "Choose valid dates. The start date must be on or before the end date."
              );
              return;
            }

            setAnalysisParams({
              latitude: String(lat),
              longitude: String(lon),
              start_date: startDate,
              end_date: endDate,
              threshold_c: String(limit),
            });
          }}
        >
          <label>
            Latitude
            <input
              type="number"
              step="any"
              min="-90"
              max="90"
              value={latitude}
              onChange={(event) => setLatitude(event.target.value)}
              required
            />
          </label>

          <label>
            Longitude
            <input
              type="number"
              step="any"
              min="-180"
              max="180"
              value={longitude}
              onChange={(event) => setLongitude(event.target.value)}
              required
            />
          </label>

          <label>
            Start date
            <input
              type="date"
              value={startDate}
              onChange={(event) => setStartDate(event.target.value)}
              required
            />
          </label>

          <label>
            End date
            <input
              type="date"
              value={endDate}
              onChange={(event) => setEndDate(event.target.value)}
              min={startDate || undefined}
              required
            />
          </label>

          <label>
            Heat threshold (°C)
            <input
              type="number"
              step="0.5"
              min="-50"
              max="70"
              value={threshold}
              onChange={(event) => setThreshold(event.target.value)}
              required
            />
          </label>

          <div className="agriculture-form-action">
            <button type="submit" disabled={agricultureLoading}>
              {agricultureLoading ? "Analysing…" : "Run analysis"}
            </button>
          </div>
        </form>
      </div>





      <div className="agriculture-header">
        <div>
          <h3>Maize heat screening</h3>
          <p>Test location near Bloemfontein · 1–7 October 2026</p>
        </div>
        <span className="api-status">
          {agricultureLoading ? "Loading…" : agricultureError ? "API error" : agricultureData ? "API connected" : "Awaiting data"}
        </span>
      </div>

      {agricultureLoading && <p>Loading agriculture data…</p>}

      {agricultureError && (
        <p role="alert">
          Could not load agriculture data: {agricultureError}
        </p>
      )}

      {agricultureData && (
        <>
          <div className="agriculture-metrics">
            <div className="agriculture-metric">
              <span>Days with data</span>
              <strong>{agricultureData.days_with_data}</strong>
            </div>
            <div className="agriculture-metric">
              <span>Missing days</span>
              <strong>{agricultureData.missing_days}</strong>
            </div>
            <div className="agriculture-metric">
              <span>Days above threshold</span>
              <strong>{agricultureData.days_above_threshold}</strong>
            </div>
            <div className="agriculture-metric">
              <span>Heat exceedance</span>
              <strong>{agricultureData.cumulative_exceedance_c_days} °C-days</strong>
            </div>
          </div>

          <div className="agriculture-chart-panel">
            <h3>Daily maximum temperature</h3>
            <p>Provisional screening threshold: {agricultureData.threshold_c}°C</p>

            <div className="temperature-chart">
              {agricultureData.daily_results.map((day) => (
                <div className="temperature-column" key={day.date}>
                  <span className="temperature-value">
                    {day.maximum_c.toFixed(1)}°
                  </span>
                  <div className="temperature-bar-area">
                    <div
                      className="temperature-bar"
                      
                      
        style={{
          height: `${
            Math.max(
              4,
              (day.maximum_c /
                (Math.max(
                  agricultureData.threshold_c,
                  ...agricultureData.daily_results.map(
                    (result) => result.maximum_c
                  ),
                  1
                ) * 1.1)
              ) * 100
            )
          }%`,
        }}


                      title={`${day.date}: ${day.maximum_c}°C`}
                    />
                  </div>
                  <span className="temperature-date">
                    {day.date.slice(8, 10)} Oct
                  </span>
                </div>
              ))}
            </div>

            <p className="agriculture-note">
              {agricultureData.interpretation}
            </p>
          </div>
        </>
      )}
    </div>
  )}


              <button className="back-button" onClick={() => setActive("Overview")}>
                ← Return to overview
              </button>
            </section>
          )}

          <footer className="page-footer">
            <span>KEULDER PLATFORM</span>
            <span>Local development · Version 1 foundation</span>
          </footer>
        </div>
      </main>
    </div>
  );
}
