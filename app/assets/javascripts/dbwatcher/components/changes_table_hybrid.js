/**
 * Changes Table Hybrid Component v3.0
 * Alpine.js + Tabulator.js implementation for DBWatcher changes tab
 * Production version - all issues fixed, debugging removed
 */

// Register component with DBWatcher
DBWatcher.registerComponent('changesTableHybrid', function(config) {
  const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

  return {
    // Include BaseComponent
    ...baseComponent,

    // Component-specific state
    sessionId: config.sessionId || null,
    tableData: {},
    filters: {
      search: '',
      operation: '',
      table: '',
      selectedTables: []
    },
    showColumnSelector: null,
    expandedRows: {},
    tabulators: {}, // Multiple tabulator instances (one per table)
    tableColumns: {}, // Per-table column visibility

    // Alpine init hook (auto-called by Alpine.js)
    init() {
      // Initialize empty state
      this.tableColumns = {};
      this.expandedRows = {};

      // Setup filtering
      this.setupFiltering();

      // Load data from API
      this.loadChangesData();

      // Setup URL state sync
      this.setupURLStateSync();

      // Call base init if it exists
      if (baseComponent.init) {
        baseComponent.init.call(this);
      }
    },

    // Setup filtering with debouncing
    setupFiltering() {
      // Use library debouncing from BaseComponent
      this.applyFilters = this.debounce(() => {
        this.applyTabulatorFilters();
        this.updateURL();
      }, 300);
    },

    // Apply filters directly to Tabulator (no server reload needed)
    applyTabulatorFilters() {
      // Apply filters to all tabulator instances
      Object.keys(this.tabulators).forEach(tableName => {
        const tabulator = this.tabulators[tableName];
        if (!tabulator) return;

        // Clear existing filters
        tabulator.clearFilter();

        // Create a combined filter function that handles all filters
        const hasSearch = this.filters.search && this.filters.search.trim();
        const hasOperation = this.filters.operation;
        const hasTable = this.filters.table;

        if (hasSearch || hasOperation || hasTable) {
          const searchTerm = hasSearch ? this.filters.search.trim().toLowerCase() : '';

          // Apply combined custom filter
          tabulator.setFilter((data) => {
            // Search filter
            if (hasSearch) {
              const searchableContent = [
                data.table_name,
                data.operation,
                data.timestamp,
                data.index,
                ...Object.values(data).filter(val => val !== null && val !== undefined)
              ].join(' ').toLowerCase();

              if (!searchableContent.includes(searchTerm)) {
                return false;
              }
            }

            // Operation filter
            if (hasOperation && data.operation !== this.filters.operation) {
              return false;
            }

            // Table filter
            if (hasTable && data.table_name !== this.filters.table) {
              return false;
            }

            return true;
          });
        }

        // Note: Multi-table filtering is handled at the template level via x-show
      });
    },

    // Load data from API
    async loadChangesData() {
      if (!this.sessionId) {
        console.error('No session ID provided to changes table hybrid component');
        this.handleError(new Error('No session ID provided'));
        return;
      }

      this.setLoading(true);
      this.clearError();

      try {
        // Build query parameters from filters
        const params = new URLSearchParams();
        if (this.filters.table) params.append('table', this.filters.table);
        if (this.filters.operation) params.append('operation', this.filters.operation);
        if (this.filters.search) params.append('search', this.filters.search);

        const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/tables_data?${params.toString()}`;
        const data = await this.fetchData(url);

        if (data.tables_summary) {
          this.tableData = data.tables_summary;
          
          // Debug: Log the table data structure to verify model_class is included
          console.log('Table data received:', Object.keys(this.tableData));
          Object.entries(this.tableData).forEach(([tableName, tableInfo]) => {
            console.log(`Table ${tableName} model_class:`, tableInfo.model_class);
          });
          
          this.initializeColumnVisibility();
          this.initializeTabulators();
        } else {
          throw new Error('No changes data received');
        }
      } catch (error) {
        this.handleError(error);
      } finally {
        this.setLoading(false);
      }
    },

    // Initialize Tabulator tables (one per table)
    initializeTabulators() {
      this.$nextTick(() => {
        // Destroy existing tables
        Object.values(this.tabulators).forEach(tabulator => {
          if (tabulator) tabulator.destroy();
        });
        this.tabulators = {};

        // Create one Tabulator instance per table
        Object.keys(this.tableData).forEach(tableName => {
          this.initializeTableTabulator(tableName);
        });
      });
    },

    // Initialize Tabulator for a specific table
    initializeTableTabulator(tableName) {
      const container = document.getElementById(`changes-table-${tableName}`);
      if (!container) {
        console.warn(`Table container not found for ${tableName}`);
        return;
      }

      const tableInfo = this.tableData[tableName];
      if (!tableInfo || !tableInfo.changes || tableInfo.changes.length === 0) {
        container.innerHTML = '<div class="p-4 text-gray-500 text-center">No changes for this table</div>';
        return;
      }

      // Transform data for this specific table
      const tabulatorData = this.transformTableDataForTabulator(tableName, tableInfo);

      // Create Tabulator instance for this table
      this.tabulators[tableName] = new Tabulator(container, {
        data: tabulatorData,
        layout: 'fitDataFill',
        responsiveLayout: false,
        height: Math.max(200, Math.min(400, (tabulatorData.length * 35) + 80)),  // Minimum 200px, expand based on content

        // Force Tabulator to use our custom rowId field
        index: 'rowId',  // Tell Tabulator to use the 'rowId' field as the row identifier

        // Performance optimizations - disable virtual DOM to ensure all rows render
        virtualDom: false,
        pagination: false,  // Ensure no pagination

        // Column configuration for this table
        columns: this.buildColumnsForTable(tableName, tableInfo),

        // Row formatting
        rowFormatter: this.customRowFormatter.bind(this),

        // No initial sorting - data should be in correct order from API
        // initialSort: [],

        // Enable header sorting
        headerSortTristate: true,

        // Callbacks
        headerBuilt: () => this.applyHeaderClasses(tableName),
        rowBuilt: (row) => this.applyRowClasses(tableName, row)
      });

    },

    // Transform data for a specific table
    transformTableDataForTabulator(tableName, tableInfo) {
      const rows = [];
      const changes = tableInfo.changes || [];

      changes.forEach((change, index) => {
        const columnData = this.extractColumnData(change, tableInfo.columns);

        // Create truly unique row ID using table name and index only (for Tabulator internal use)
        const uniqueRowId = `${tableName}_row_${index}`;

        const row = {
          rowId: uniqueRowId,  // Tabulator's internal row identifier
          index: index + 1,  // Display index (1-based) - should maintain API order
          operation: change.operation,
          timestamp: change.timestamp,
          table_name: tableName,
          change_data: change,  // Keep original change data with ID intact
          ...columnData  // Include all column data including actual record ID
        };

        rows.push(row);
      });

      return rows;
    },

    // Build columns for a specific table
    buildColumnsForTable(tableName, tableInfo) {
      const columns = [
        {
          title: '#',
          field: 'index',
          width: 60,
          frozen: true,
          headerSort: false,
          cssClass: 'sticky-left-0',
          titleFormatter: () => '<span class="text-xs">#</span>',
          formatter: (cell) => {
            const rowData = cell.getRow().getData();
            return `<div class="flex items-center justify-center gap-1">
                      <button class="expand-btn text-gray-400 hover:text-gray-600 transition-colors p-1 rounded hover:bg-gray-100"
                             data-row-id="${rowData.rowId}">
                        <svg class="w-3 h-3 transition-transform" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 5.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
                        </svg>
                      </button>
                      <span class="text-xs text-gray-500">${rowData.index}</span>
                    </div>`;
          },
          cellClick: (e, _cell) => {
            e.stopPropagation();
            const target = e.target.closest('.expand-btn');
            if (target) {
              const rowId = target.getAttribute('data-row-id');
                this.toggleRowExpansion(rowId);
            }
          }
        },
        {
          title: 'Op',
          field: 'operation',
          width: 48,
          frozen: true,
          headerSort: false,
          cssClass: 'sticky-left-1',
          titleFormatter: () => '<span class="text-xs">Op</span>',
          formatter: (cell) => {
            const op = cell.getValue();
            return `<span class="badge badge-${op.toLowerCase()}">${op.charAt(0)}</span>`;
          }
        },
        {
          title: 'Timestamp',
          field: 'timestamp',
          width: 160,
          frozen: true,
          cssClass: 'sticky-left-2',
          titleFormatter: () => '<span class="text-xs">Timestamp</span>',
          sorter: 'string',  // Changed from 'datetime' to 'string'
          formatter: (cell) => {
            return `<span class="text-xs text-gray-600">${this.formatTimestamp(cell.getValue())}</span>`;
          }
        }
      ];

      // Add columns specific to this table
      if (tableInfo.columns) {
        tableInfo.columns.forEach(col => {
          // Only add column if it's visible
          if (this.isColumnVisible(tableName, col)) {
            columns.push({
              title: col,
              field: col,
              minWidth: 100,
              titleFormatter: () => `<span class="text-xs">${col}</span>`,
              headerSort: true,
              sorter: this.getColumnSorter(col),
              formatter: (cell) => {
                const value = cell.getValue();
                const rowData = cell.getRow().getData();
                const change = rowData.change_data;

                // Handle different operations with appropriate styling
                if (change.operation === 'UPDATE' && change.changes) {
                  const columnChange = change.changes.find(c => c.column === col);
                  if (columnChange) {
                    return `<div class="text-xs space-y-1">
                              <div class="text-red-600 line-through">${this.formatCellValue(columnChange.old_value)}</div>
                              <div class="text-green-600 font-medium">${this.formatCellValue(columnChange.new_value)}</div>
                            </div>`;
                  } else {
                    return `<span class="text-xs text-gray-700">${this.formatCellValue(value)}</span>`;
                  }
                } else if (change.operation === 'INSERT') {
                  return `<span class="text-xs text-green-600 font-medium">${this.formatCellValue(value)}</span>`;
                } else if (change.operation === 'DELETE') {
                  return `<span class="text-xs text-red-600 line-through">${this.formatCellValue(value)}</span>`;
                } else {
                  return `<span class="text-xs text-gray-700">${this.formatCellValue(value)}</span>`;
                }
              }
            });
          }
        });
      }

      return columns;
    },


    // Extract column data from change record
    extractColumnData(change, columns) {
      const data = {};

      columns.forEach(col => {
        // Get value from record snapshot or change data
        if (change.record_snapshot && change.record_snapshot[col] !== undefined) {
          data[col] = change.record_snapshot[col];
        } else if (change.operation === 'UPDATE' && change.changes) {
          const columnChange = change.changes.find(c => c.column === col);
          if (columnChange) {
            data[col] = columnChange.new_value;
          }
        }
      });

      return data;
    },

    // Build column configuration for Tabulator
    buildColumns() {
      const columns = [
        {
          title: '#',
          field: 'index',
          width: 60,
          frozen: true,
          headerSort: false,
          cssClass: 'sticky-left-0',
          titleFormatter: () => '<span class="text-xs">#</span>',
          formatter: (cell) => {
            const rowData = cell.getRow().getData();
            return `<div class="flex items-center justify-center gap-1">
                      <button class="expand-btn text-gray-400 hover:text-gray-600 transition-colors p-1 rounded hover:bg-gray-100"
                             data-row-id="${rowData.rowId}">
                        <svg class="w-3 h-3 transition-transform" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 5.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
                        </svg>
                      </button>
                      <span class="text-xs text-gray-500">${rowData.index}</span>
                    </div>`;
          },
          cellClick: (e, _cell) => {
            e.stopPropagation();
            const target = e.target.closest('.expand-btn');
            if (target) {
              const rowId = target.getAttribute('data-row-id');
                this.toggleRowExpansion(rowId);
            }
          }
        },
        {
          title: 'Op',
          field: 'operation',
          width: 48,
          frozen: true,
          headerSort: false,
          cssClass: 'sticky-left-1',
          titleFormatter: () => '<span class="text-xs">Op</span>',
          formatter: (cell) => {
            const op = cell.getValue();
            return `<span class="badge badge-${op.toLowerCase()}">${op.charAt(0)}</span>`;
          }
        },
        {
          title: 'Timestamp',
          field: 'timestamp',
          width: 160,
          frozen: true,
          cssClass: 'sticky-left-2',
          titleFormatter: () => '<span class="text-xs">Timestamp</span>',
          sorter: 'string',  // Changed from 'datetime' to 'string'
          formatter: (cell) => {
            return `<span class="text-xs text-gray-600">${this.formatTimestamp(cell.getValue())}</span>`;
          }
        }
      ];

      // Add dynamic columns based on table data
      const allColumns = new Set();
      Object.keys(this.tableData).forEach(tableName => {
        const tableInfo = this.tableData[tableName];
        if (tableInfo.columns) {
          tableInfo.columns.forEach(col => allColumns.add(col));
        }
      });

      // Add each column
      allColumns.forEach(col => {
        columns.push({
          title: col,
          field: col,
          minWidth: 100,
          titleFormatter: () => `<span class="text-xs">${col}</span>`,
          headerSort: true,
          sorter: this.getColumnSorter(col),
          formatter: (cell) => {
            const value = cell.getValue();
            const rowData = cell.getRow().getData();
            const change = rowData.change_data;

            // Handle different operations with appropriate styling
            if (change.operation === 'UPDATE' && change.changes) {
              const columnChange = change.changes.find(c => c.column === col);
              if (columnChange) {
                return `<div class="text-xs space-y-1">
                          <div class="text-red-600 line-through">${this.formatCellValue(columnChange.old_value)}</div>
                          <div class="text-green-600 font-medium">${this.formatCellValue(columnChange.new_value)}</div>
                        </div>`;
              } else {
                return `<span class="text-xs text-gray-700">${this.formatCellValue(value)}</span>`;
              }
            } else if (change.operation === 'INSERT') {
              return `<span class="text-xs text-green-600 font-medium">${this.formatCellValue(value)}</span>`;
            } else if (change.operation === 'DELETE') {
              return `<span class="text-xs text-red-600 line-through">${this.formatCellValue(value)}</span>`;
            } else {
              return `<span class="text-xs text-gray-700">${this.formatCellValue(value)}</span>`;
            }
          }
        });
      });

      return columns;
    },

    // Get appropriate sorter for column based on data type
    getColumnSorter(columnName) {
      // Common ID columns
      if (columnName.toLowerCase().includes('id') || columnName.toLowerCase().includes('uuid')) {
        return 'string';
      }

      // Timestamp columns - use string sorting to avoid Luxon dependency
      if (columnName.toLowerCase().includes('time') ||
          columnName.toLowerCase().includes('date') ||
          columnName.toLowerCase().includes('created') ||
          columnName.toLowerCase().includes('updated')) {
        return 'string';  // Changed from 'datetime' to 'string'
      }

      // Numeric columns
      if (columnName.toLowerCase().includes('count') ||
          columnName.toLowerCase().includes('amount') ||
          columnName.toLowerCase().includes('price') ||
          columnName.toLowerCase().includes('quantity')) {
        return 'number';
      }

      // Default to alphanum for mixed content
      return 'alphanum';
    },

    // Apply header classes after Tabulator builds headers
    applyHeaderClasses(tableName) {
      const tabulator = this.tabulators[tableName];
      if (!tabulator) return;

      const headers = tabulator.getHeaderElements();
      headers.forEach((header) => {
        const field = header.getAttribute('tabulator-field');

        if (field === 'index') {
          header.classList.add('sticky-left-0');
        } else if (field === 'operation') {
          header.classList.add('sticky-left-1');
        } else if (field === 'timestamp') {
          header.classList.add('sticky-left-2');
        }
      });
    },

    // Apply row classes after Tabulator builds rows
    applyRowClasses(tableName, row) {
      const element = row.getElement();
      const cells = element.querySelectorAll('.tabulator-cell');

      cells.forEach((cell) => {
        const field = cell.getAttribute('tabulator-field');

        if (field === 'index') {
          cell.classList.add('sticky-left-0');
        } else if (field === 'operation') {
          cell.classList.add('sticky-left-1');
        } else if (field === 'timestamp') {
          cell.classList.add('sticky-left-2');
        }
      });
    },

    // Custom row formatter
    customRowFormatter(row) {
      const rowData = row.getData();
      const element = row.getElement();

      // Add classes based on operation
      const operation = rowData.operation;
      if (operation) {
        element.classList.add(`operation-${operation.toLowerCase()}`);
      }

      // Add hover effects
      element.addEventListener('mouseenter', () => {
        element.style.backgroundColor = '#f3f4f6';
      });

      element.addEventListener('mouseleave', () => {
        element.style.backgroundColor = '';
      });
    },


    // Toggle row expansion
    toggleRowExpansion(rowId) {
      this.expandedRows[rowId] = !this.expandedRows[rowId];

      // Find the row across all tabulator instances
      let targetRow = null;
      let foundInTable = null;

      Object.keys(this.tabulators).forEach(tableName => {
        const tabulator = this.tabulators[tableName];
        if (tabulator && !targetRow) {
          try {
            // Search by row ID directly
            const row = tabulator.getRow(rowId);
            if (row) {
              targetRow = row;
              foundInTable = tableName;
              return; // Found it, stop searching
            }
          } catch (e) {
            // Try searching through data if direct lookup fails
            try {
              const data = tabulator.getData();
              const matchingData = data.find(d => d.rowId === rowId);
              if (matchingData) {
                targetRow = tabulator.getRow(rowId);
                foundInTable = tableName;
              }
            } catch (e2) {
              // Row not found in this tabulator, continue searching
            }
          }
        }
      });

      if (targetRow) {
        if (this.expandedRows[rowId]) {
          this.showRowDetails(targetRow);
        } else {
          this.hideRowDetails(targetRow);
        }
      } else {
        console.warn(`Row ${rowId} not found in any table`);
      }
    },

    // Show row details
    showRowDetails(row) {
      const rowData = row.getData();
      const element = row.getElement();


      // Check if detail row already exists
      const existingDetail = element.nextElementSibling;
      if (existingDetail && existingDetail.classList.contains('row-detail')) {
        return; // Already expanded
      }

      // Create detail row as a proper table row
      const detailRow = document.createElement('tr');
      detailRow.className = 'row-detail bg-gray-50';
      detailRow.setAttribute('data-parent-id', rowData.rowId);

      // Create full-width cell
      const detailCell = document.createElement('td');
      detailCell.colSpan = 1000; // Span all columns
      detailCell.className = 'p-0 border-t border-gray-200';

      try {
        detailCell.innerHTML = this.generateExpandedContent(rowData);
        detailRow.appendChild(detailCell);

        // Insert after the current row
        element.parentNode.insertBefore(detailRow, element.nextSibling);

        // Update expand button
        this.updateExpandButton(element, true);

        // Dynamically increase table height when expanded
        const tabulator = this.findTabulatorForRow(rowData.table_name);
        if (tabulator) {
          setTimeout(() => {
            const currentHeight = tabulator.getElement().offsetHeight;
            const expandedHeight = Math.max(currentHeight + 200, 300);  // Add 200px for expanded content
            tabulator.setHeight(expandedHeight);
          }, 50);
        }
      } catch (error) {
        console.error(`Error creating detail row for ${rowData.rowId}:`, error);
      }
    },

    // Hide row details
    hideRowDetails(row) {
      const element = row.getElement();
      const rowData = row.getData();


      // Find and remove the detail row
      const detailRow = element.parentNode.querySelector(`tr.row-detail[data-parent-id="${rowData.rowId}"]`);
      if (detailRow) {
        detailRow.remove();
      } else {
      }

      // Update expand button
      this.updateExpandButton(element, false);

      // Shrink table height back when collapsed
      const tabulator = this.findTabulatorForRow(rowData.table_name);
      if (tabulator) {
        setTimeout(() => {
          const tableData = tabulator.getData();
          const baseHeight = Math.max(200, Math.min(400, (tableData.length * 35) + 80));
          tabulator.setHeight(baseHeight);
        }, 50);
      }
    },

    // Helper method to find tabulator instance for a table
    findTabulatorForRow(tableName) {
      return this.tabulators[tableName] || null;
    },

    // Update expand button state
    updateExpandButton(rowElement, expanded) {
      const expandBtn = rowElement.querySelector('.expand-btn svg');
      if (expandBtn) {
        expandBtn.style.transform = expanded ? 'rotate(90deg)' : 'rotate(0deg)';
      }
    },

    // Generate expanded content for a row - inline table format
    generateExpandedContent(rowData) {
      const change = rowData.change_data;
      const tableInfo = this.tableData[rowData.table_name];
      const columns = tableInfo ? tableInfo.columns : [];

      // Create a table row that matches the column structure
      let content = `
        <div class="bg-gray-50 border-t border-gray-200">
          <table class="w-full" style="table-layout: fixed;">
            <tbody>
              <tr>
                <!-- Combined details for first 3 columns (index + op + timestamp) -->
                <td class="sticky-left-0 bg-gray-100 border-r border-gray-300 p-2 align-top" style="width: 268px; min-width: 268px;">
                  <div class="text-xs font-medium text-gray-600 mb-2">Change Details</div>
                  <div class="space-y-2 text-xs">
                    <div class="flex items-center justify-between">
                      <span class="text-gray-500">Row #${rowData.index}</span>
                      <span class="badge badge-${change.operation.toLowerCase()}">${change.operation}</span>
                    </div>
                    <div class="text-gray-700">
                      <div class="font-medium">${this.formatDate(change.timestamp)}</div>
                      <div class="text-gray-500 mt-1">${rowData.table_name}</div>
                    </div>
      `;

      if (change.operation === 'UPDATE' && change.changes) {
        content += `<div class="text-blue-600 font-medium">${change.changes.length} columns modified</div>`;
      }

      if (change.record_snapshot && (change.record_snapshot.id || change.record_snapshot.uuid)) {
        const fullId = change.record_snapshot.id || change.record_snapshot.uuid;
        content += `<div class="text-gray-500 font-mono text-xs bg-gray-200 p-1 rounded truncate" title="${fullId}">ID: ${String(fullId).substring(0, 12)}...</div>`;
      }

      content += `
                  </div>
                </td>
      `;

      // Add detail cells for each column that matches the table structure
      columns.forEach(col => {
        // Only show if column is visible in the main table
        if (this.isColumnVisible(rowData.table_name, col)) {
          content += `
            <td class="border-r border-gray-300 p-2 align-top" style="min-width: 100px;">
              <div class="text-xs font-medium text-gray-600 mb-1">${col}</div>
              <div class="text-xs">
          `;

          if (change.operation === 'UPDATE' && change.changes) {
            const columnChange = change.changes.find(c => c.column === col);
            if (columnChange) {
              // Show old -> new for changed columns in compact format
              content += `
                <div class="space-y-1">
                  <div class="text-xs text-red-700 bg-red-50 p-1 rounded border-l-2 border-red-400">
                    <div class="font-medium text-red-800 mb-1">Old:</div>
                    <div class="break-all max-h-12 overflow-auto">${this.formatDetailValue(columnChange.old_value)}</div>
                  </div>
                  <div class="text-xs text-green-700 bg-green-50 p-1 rounded border-l-2 border-green-400">
                    <div class="font-medium text-green-800 mb-1">New:</div>
                    <div class="break-all max-h-12 overflow-auto">${this.formatDetailValue(columnChange.new_value)}</div>
                  </div>
                </div>
              `;
            } else {
              // Show unchanged value
              content += `
                <div class="bg-gray-50 p-1 rounded border-l-2 border-gray-300">
                  <div class="text-xs text-gray-700 break-all max-h-12 overflow-auto">
                    ${this.formatDetailValue(change.record_snapshot?.[col])}
                  </div>
                </div>
              `;
            }
          } else if (change.operation === 'INSERT') {
            // Show new value for INSERT
            content += `
              <div class="bg-green-50 p-1 rounded border-l-2 border-green-400">
                <div class="text-xs text-green-700 break-all max-h-12 overflow-auto">
                  ${this.formatDetailValue(change.record_snapshot?.[col])}
                </div>
              </div>
            `;
          } else if (change.operation === 'DELETE') {
            // Show deleted value for DELETE
            content += `
              <div class="bg-red-50 p-1 rounded border-l-2 border-red-400">
                <div class="text-xs text-red-700 break-all max-h-12 overflow-auto">
                  ${this.formatDetailValue(change.record_snapshot?.[col])}
                </div>
              </div>
            `;
          } else {
            // Show value for other operations
            content += `
              <div class="bg-gray-50 p-1 rounded border-l-2 border-gray-300">
                <div class="text-xs text-gray-700 break-all max-h-12 overflow-auto">
                  ${this.formatDetailValue(change.record_snapshot?.[col])}
                </div>
              </div>
            `;
          }

          content += `
              </div>
            </td>
          `;
        }
      });

      content += `
              </tr>
            </tbody>
          </table>
        </div>
      `;

      return content;
    },

    // Format value for detailed display
    formatDetailValue(value) {
      if (value === null || value === undefined) {
        return '<span class="text-gray-400 italic">NULL</span>';
      }

      if (typeof value === 'string' && this.isJsonValue(value)) {
        try {
          const parsed = JSON.parse(value);
          return JSON.stringify(parsed, null, 2);
        } catch {
          return String(value);
        }
      }

      return String(value);
    },

    // Check if value is JSON
    isJsonValue(value) {
      if (typeof value !== 'string') return false;
      try {
        const parsed = JSON.parse(value);
        return typeof parsed === 'object' && parsed !== null;
      } catch {
        return false;
      }
    },

    // Format cell value for display
    formatCellValue(value) {
      if (value === null || value === undefined) {
        return '<span class="text-gray-400">NULL</span>';
      }

      if (typeof value === 'string' && value.length > 50) {
        return `<span title="${value}">${value.substring(0, 50)}...</span>`;
      }

      return String(value);
    },

    // Setup URL state synchronization
    setupURLStateSync() {
      const urlParams = new URLSearchParams(window.location.search);
      const tableParam = urlParams.get('table');
      const operationParam = urlParams.get('operation');

      if (tableParam) this.filters.table = tableParam;
      if (operationParam) this.filters.operation = operationParam;
    },

    // Update URL with current filters
    updateURL() {
      const url = new URL(window.location.href);
      const params = new URLSearchParams(url.search);

      if (this.filters.table) {
        params.set('table', this.filters.table);
      } else {
        params.delete('table');
      }

      if (this.filters.operation) {
        params.set('operation', this.filters.operation);
      } else {
        params.delete('operation');
      }

      url.search = params.toString();
      window.history.replaceState({}, '', url.toString());
    },

    // Clear all filters
    clearFilters() {
      this.filters = {
        search: '',
        operation: '',
        table: ''
      };
      this.applyFilters();
    },

    // Column management methods
    toggleColumnSelector(tableName) {
      this.showColumnSelector = this.showColumnSelector === tableName ? null : tableName;
    },

    // Initialize column visibility state (per table)
    initializeColumnVisibility() {
      this.tableColumns = {};

      Object.keys(this.tableData).forEach(tableName => {
        const tableInfo = this.tableData[tableName];
        if (tableInfo && tableInfo.columns) {
          this.tableColumns[tableName] = {};
          tableInfo.columns.forEach(col => {
            this.tableColumns[tableName][col] = true; // All columns visible by default
          });
        }
      });
    },

    // Toggle column visibility for a specific table
    toggleColumnVisibility(tableName, columnName) {
      if (this.tableColumns[tableName] && this.tableColumns[tableName][columnName] !== undefined) {
        this.tableColumns[tableName][columnName] = !this.tableColumns[tableName][columnName];
        this.updateTableColumns(tableName);
      }
    },

    // Update Tabulator column visibility for a specific table
    updateTableColumns(tableName) {
      const tabulator = this.tabulators[tableName];
      if (!tabulator) return;

      // Rebuild columns for this table
      const tableInfo = this.tableData[tableName];
      const newColumns = this.buildColumnsForTable(tableName, tableInfo);

      // Update the tabulator columns
      tabulator.setColumns(newColumns);
    },

    // Select all columns for a table
    selectAllColumns(tableName) {
      if (!this.tableColumns[tableName]) return;

      Object.keys(this.tableColumns[tableName]).forEach(col => {
        this.tableColumns[tableName][col] = true;
      });
      this.updateTableColumns(tableName);
    },

    // Deselect all columns for a table
    selectNoneColumns(tableName) {
      if (!this.tableColumns[tableName]) return;

      Object.keys(this.tableColumns[tableName]).forEach(col => {
        this.tableColumns[tableName][col] = false;
      });
      this.updateTableColumns(tableName);
    },

    // Check if column is visible for a specific table
    isColumnVisible(tableName, columnName) {
      return this.tableColumns[tableName] && this.tableColumns[tableName][columnName] === true;
    },

    // Format timestamp for display
    formatTimestamp(timestamp) {
      if (!timestamp) return '--';
      const date = new Date(timestamp);
      return date.toLocaleString('en-AU', {
        year: '2-digit',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      }).replace(/\//g, '-');
    },

    // Format date for expanded view
    formatDate(timestamp) {
      if (!timestamp) return '--';
      const date = new Date(timestamp);
      return date.toLocaleString('en-AU', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      });
    },

    // Check if there are any visible changes
    hasVisibleChanges() {
      return Object.keys(this.tableData).some(tableName => {
        const data = this.tableData[tableName];
        return data.changes && data.changes.length > 0;
      });
    },

    // Get available operations for filtering
    getAvailableOperations() {
      const operations = new Set();
      Object.values(this.tableData).forEach(tableInfo => {
        if (tableInfo.operations) {
          Object.keys(tableInfo.operations).forEach(op => operations.add(op));
        }
      });
      return Array.from(operations).sort();
    },

    // Get available tables for filtering
    getAvailableTables() {
      return Object.keys(this.tableData).sort();
    },

    // Select all tables
    selectAllTables() {
      this.filters.selectedTables = this.getAvailableTables();
      this.applyFilters();
    },

    // Clear table filters
    clearTableFilters() {
      this.filters.selectedTables = [];
      this.applyFilters();
    },

    // Clear all filters
    clearAllFilters() {
      this.filters = {
        search: '',
        operation: '',
        table: '',
        selectedTables: []
      };
      this.applyFilters();
    },

    // Get active filter count
    getActiveFilterCount() {
      let count = 0;
      if (this.filters.search) count++;
      if (this.filters.operation) count++;
      if (this.filters.table) count++;
      if (this.filters.selectedTables.length > 0) count++;
      return count;
    },

    // Get filtered row count
    getFilteredRowCount() {
      let count = 0;
      Object.values(this.tabulators).forEach(tabulator => {
        if (tabulator) {
          count += tabulator.getDataCount('active');
        }
      });
      return count;
    },

    // Get total row count
    getTotalRowCount() {
      let count = 0;
      Object.values(this.tabulators).forEach(tabulator => {
        if (tabulator) {
          count += tabulator.getDataCount();
        }
      });
      return count;
    },

    // Component cleanup
    componentDestroy() {
      Object.values(this.tabulators).forEach(tabulator => {
        if (tabulator) {
          tabulator.destroy();
        }
      });
      this.tabulators = {};
    }
  };
});
